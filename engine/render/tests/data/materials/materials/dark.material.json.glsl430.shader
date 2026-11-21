{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "ae26515a48b1a8d2e7a58b8583b7398bc5ad5b1e5314aaacf65f28e91c149fe7",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1342 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1349;\n    if (!_1342)\n    {\n        _1349 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1349 = _1342;\n    }\n    bool _1357;\n    if (!_1349)\n    {\n        _1357 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1357 = _1349;\n    }\n    bool _1364;\n    if (!_1357)\n    {\n        _1364 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1364 = _1357;\n    }\n    bool _1371;\n    if (!_1364)\n    {\n        _1371 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1371 = _1364;\n    }\n    if (_1371)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1381 = vec4(world_pos, 1.0);\n    float _1387 = dot(fa_mesh_fs_params[16], _1381);\n    if (!(_1387 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1409 = vec2(dot(fa_mesh_fs_params[14], _1381), dot(fa_mesh_fs_params[15], _1381)) / vec2(_1387);\n    int _1413 = int(fa_mesh_fs_params[18].x);\n    int _1417 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1417) + clamp(int(floor(((_1409.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1417 - 1)) * _1413)) + clamp(int(floor(((_1409.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1413 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1493 = fa_cluster_texel(param);\n    return ivec2(int(_1493.x), int(_1493.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3743 = fa_cluster_lookup(param);\n    fa_cl_slot = _3743.x;\n    fa_cl_local = _3743.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3948 = fa_linear_to_srgb(param);\n        c = _3948;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3956 = fa_srgb_to_linear(param_1);\n            c = _3956;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _296;\n    if (i.front_facing)\n    {\n        _296 = i.world_normal;\n    }\n    else\n    {\n        _296 = -i.world_normal;\n    }\n    vec3 _320 = normalize(i.world_tangent.xyz - (_296 * dot(_296, i.world_tangent.xyz)));\n    vec3 _347 = normalize(((_320 * m.x) + ((cross(_296, _320) * i.world_tangent.w) * m.y)) + (_296 * m.z));\n    vec3 _350;\n    if (i.front_facing)\n    {\n        _350 = _347;\n    }\n    else\n    {\n        _350 = -_347;\n    }\n    return _350;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3987 = fa_tex_fix(param_2, param_3);\n    vec4 _5759 = base_t;\n    _5759.x = _3987.x;\n    _5759.y = _3987.y;\n    _5759.z = _3987.z;\n    base_t = _5759;\n    vec4 _4001 = (_5759 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5596 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4033 = fa_tex_fix(param_6, param_7);\n        vec3 _4036 = (_4033 * 2.0) - vec3(1.0);\n        vec2 _4041 = _4036.xy * fa_mesh_fs_params[6].x;\n        vec3 _5767 = _4036;\n        _5767.x = _4041.x;\n        _5767.y = _4041.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5767;\n        _5596 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4069 = fa_tex_fix(param_12, param_13);\n    vec4 _5770 = mrt;\n    _5770.x = _4069.x;\n    _5770.y = _4069.y;\n    _5770.z = _4069.z;\n    mrt = _5770;\n    vec4 _4097 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4097.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4108 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4138 = fa_tex_fix(param_20, param_21);\n    float _5601 = fa_mesh_fs_params[20].x;\n    float _5602 = fa_mesh_fs_params[20].y;\n    float _5605 = fa_mesh_fs_params[20].z;\n    float _5604 = fa_mesh_fs_params[21].w;\n    float _5607 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5601 *= _4108.y;\n            _5602 *= _4108.z;\n            _5604 *= _4097.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5605 *= mrt.x;\n            _5607 *= mrt.w;\n        }\n    }\n    return Surface(_4001.xyz, _4001.w, _5596, clamp(fa_mesh_fs_params[5].x * _4069.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4069.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4108.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4138), _5601, _5602, fa_mesh_fs_params[21].xyz, _5604, _5605, fa_mesh_fs_params[20].w, _5607, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1573 = rect.zw - rect.xy;\n    vec2 _1577 = _1573 * atlas;\n    vec2 _1581 = ddx * _1577;\n    vec2 _1585 = ddy * _1577;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1573), clamp(0.5 * log2(max(max(dot(_1581, _1581), dot(_1585, _1585)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1618 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1625;\n    if (!_1618)\n    {\n        _1625 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1625 = _1618;\n    }\n    if (_1625)\n    {\n        return;\n    }\n    vec3 _1631 = dFdx(world_pos);\n    vec3 _1634 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1638 = fa_cluster_texel(param);\n    int _1642 = int(_1638.w);\n    if (_1642 < 1)\n    {\n        return;\n    }\n    int _1652 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1652;\n    vec4 _1656 = fa_light_texel(param_1);\n    vec2 _1659 = _1656.yz;\n    int _1663 = int(_1656.w);\n    int param_2 = _1652 + 1;\n    vec4 _1668 = fa_light_texel(param_2);\n    float _1669 = _1668.x;\n    int _1675 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1679 = int(_1638.z);\n    vec3 _1944;\n    for (int k = 0; k < _1642; k++)\n    {\n        int _1692 = _1679 + k;\n        int param_3 = _1663 + (_1692 >> 2);\n        int _1709 = (_1652 + 2) + (int(fa_light_texel(param_3)[_1692 & 3]) * 7);\n        int param_4 = _1709 + 6;\n        vec4 _1714 = fa_light_texel(param_4);\n        if (((int(_1714.w + 0.5) >> _1675) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1709;\n        vec4 _1729 = fa_light_texel(param_5);\n        int param_6 = _1709 + 1;\n        vec4 _1734 = fa_light_texel(param_6);\n        int param_7 = _1709 + 2;\n        vec4 _1739 = fa_light_texel(param_7);\n        vec3 _1742 = _1729.xyz;\n        float _1747 = dot(_1742, world_pos) + _1729.w;\n        vec3 _1749 = _1734.xyz;\n        float _1754 = dot(_1749, world_pos) + _1734.w;\n        vec3 _1756 = _1739.xyz;\n        float _1761 = dot(_1756, world_pos) + _1739.w;\n        bool _1766 = abs(_1747) > 0.5;\n        bool _1774;\n        if (!_1766)\n        {\n            _1774 = abs(_1754) > 0.5;\n        }\n        else\n        {\n            _1774 = _1766;\n        }\n        bool _1782;\n        if (!_1774)\n        {\n            _1782 = abs(_1761) > 0.5;\n        }\n        else\n        {\n            _1782 = _1774;\n        }\n        if (_1782)\n        {\n            continue;\n        }\n        float _1797 = clamp(dot(geo_normal, normalize(_1756)) * _1714.z, 0.0, 1.0);\n        if (_1797 <= 0.0)\n        {\n            continue;\n        }\n        float _1817 = (clamp((0.5 - abs(_1761)) * 10.0, 0.0, 1.0) * _1797) * _1714.x;\n        vec2 _1825 = vec2(_1747 + 0.5, 0.5 - _1754);\n        vec2 _1835 = vec2(dot(_1742, _1631), dot(_1749, _1631));\n        vec2 _1845 = vec2(dot(_1742, _1634), dot(_1749, _1634));\n        int param_8 = _1709 + 5;\n        vec4 _1850 = fa_light_texel(param_8);\n        int param_9 = _1709 + 3;\n        vec4 _1855 = fa_light_texel(param_9);\n        int param_10 = _1709 + 4;\n        vec4 _1860 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1850.xyz;\n        bool _1870 = _1855.z > _1855.x;\n        if (_1870)\n        {\n            vec4 param_11 = _1855;\n            vec2 param_12 = _1825;\n            vec2 param_13 = _1659;\n            vec2 param_14 = _1835;\n            vec2 param_15 = _1845;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1669 > 0.5) && (_1669 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1896 = fa_dc_to_linear(param_16);\n                vec4 _5684 = tx;\n                _5684.x = _1896.x;\n                _5684.y = _1896.y;\n                _5684.z = _1896.z;\n                tx = _5684;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1817 * tex_a) * _1850.w, 0.0, 1.0)));\n        if (_1860.z > _1860.x)\n        {\n            vec4 param_17 = _1860;\n            vec2 param_18 = _1825;\n            vec2 param_19 = _1659;\n            vec2 param_20 = _1835;\n            vec2 param_21 = _1845;\n            vec4 _1940 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1669 > 1.5)\n            {\n                vec3 param_22 = _1940.xyz;\n                vec3 _1950 = fa_dc_to_srgb(param_22);\n                _1944 = _1950;\n            }\n            else\n            {\n                _1944 = _1940.xyz;\n            }\n            vec3 _1959 = (_1944 * 2.0) - vec3(1.0);\n            vec2 _1964 = _1959.xy * _1714.y;\n            vec3 _1986 = (normalize(_1742) * _1964.x) + (normalize(_1749) * _1964.y);\n            vec3 _1989 = normalize(normal);\n            normal = normalize(mix(_1989, normalize((_1989 * max(_1959.z, 0.0500000007450580596923828125)) + (_1986 - (_1989 * dot(_1989, _1986)))), vec3(clamp(_1817 * (_1870 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3197 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3197;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3307 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3313 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3307 > 0.0005000000237487256526947021484375)\n    {\n        if (_3313)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3307;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3307;\n        }\n    }\n    bool _3365 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3365)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3396 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3396)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3313 || _3365) || _3396)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3217 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3220 = _3217.x;\n    float _3222 = _3217.z;\n    vec2 e = vec2(_3220, _3222);\n    if (_3217.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3222)) * ((_3220 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3220)) * ((_3222 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _4252 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _4257 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _4262 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _4267 = fa_light_texel(param_3);\n    bool _4270 = _4267.z < 0.5;\n    bool _4278;\n    if (!_4270)\n    {\n        _4278 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _4278 = _4270;\n    }\n    if (_4278)\n    {\n        return vec3(0.0);\n    }\n    float _4285 = max(_4252.w, 9.9999997473787516355514526367188e-05);\n    vec3 _4288 = _4257.xyz;\n    vec3 _4292 = _4252.xyz;\n    vec3 _4296 = (fa_world_pos - _4292) / vec3(_4285);\n    vec3 _4305 = min(_4296 + vec3(0.5), (_4288 - vec3(0.5)) - _4296);\n    float _4314 = min(_4305.x, min(_4305.y, _4305.z));\n    if (!(_4314 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4329 = _4288 - vec3(1.0);\n    vec3 _4330 = clamp(_4296, vec3(0.0), _4329);\n    vec3 _4338 = min(floor(_4330), max(_4288 - vec3(2.0), vec3(0.0)));\n    vec3 _4342 = _4330 - _4338;\n    vec3 _4354 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _4285));\n    int _4359 = int(_4262.y + 0.5);\n    float _4364 = 0.3257350027561187744140625 * n.y;\n    float _4368 = 0.3257350027561187744140625 * n.z;\n    float _4372 = 0.3257350027561187744140625 * n.x;\n    float _4379 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _4386 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _4395 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _4402 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _4415 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _4422 = 8 + int(_4267.w);\n    float _4449;\n    float _4462;\n    float _4476;\n    for (int k = 0; k < _4422; k++)\n    {\n        float _4435 = float(k & 1);\n        float _4439 = float((k >> 1) & 1);\n        float _4443 = float((k >> 2) & 1);\n        if (_4435 > 0.5)\n        {\n            _4449 = _4342.x;\n        }\n        else\n        {\n            _4449 = 1.0 - _4342.x;\n        }\n        if (_4439 > 0.5)\n        {\n            _4462 = _4342.y;\n        }\n        else\n        {\n            _4462 = 1.0 - _4342.y;\n        }\n        if (_4443 > 0.5)\n        {\n            _4476 = _4342.z;\n        }\n        else\n        {\n            _4476 = 1.0 - _4342.z;\n        }\n        float _4486 = (_4449 * _4462) * _4476;\n        if (!(_4486 > 0.0))\n        {\n            continue;\n        }\n        vec3 _4499 = min(_4338 + vec3(_4435, _4439, _4443), _4329);\n        int _4519 = int(((_4262.x + _4499.x) + (_4257.x * (_4499.y + (_4257.y * _4499.z)))) + 0.5);\n        vec2 _4534 = vec2(float(_4519 % _4359) * 10.0, 1024.0 + (float(_4519 / _4359) * 11.0));\n        vec2 param_4 = _4534 + vec2(9.5, 10.5);\n        vec4 _4542 = fa_gi_fetch(param_4);\n        bool _4545 = _4542.y < 0.5;\n        bool _4554;\n        if (!_4545)\n        {\n            _4554 = _4542.x > _4267.y;\n        }\n        else\n        {\n            _4554 = _4545;\n        }\n        if (_4554)\n        {\n            continue;\n        }\n        vec3 _4566 = _4354 - (_4292 + (_4499 * _4285));\n        float _4569 = length(_4566);\n        vec3 _4575 = _4566 / vec3(max(_4569, 9.9999997473787516355514526367188e-05));\n        float _4585 = max(9.9999997473787516355514526367188e-05, (dot(-_4575, n) + 1.0) * 0.5);\n        float w = _4486 * (_4585 * _4585);\n        vec3 param_5 = _4575;\n        vec2 param_6 = (_4534 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _4605 = fa_gi_fetch(param_6);\n        float _4612 = _4569 / max(_4262.z, 9.9999997473787516355514526367188e-05);\n        float _4615 = _4605.x;\n        if (_4612 > _4615)\n        {\n            float _4628 = max(_4605.y - (_4615 * _4615), 0.0);\n            float _4633 = _4612 - _4615;\n            float _4642 = _4628 / max(_4628 + (_4633 * _4633), 9.9999999600419720025001879548654e-13);\n            w *= ((_4642 * _4642) * _4642);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _4534 + vec2(0.5, 10.5);\n        vec2 param_8 = _4534 + vec2(1.5, 10.5);\n        vec2 param_9 = _4534 + vec2(2.5, 10.5);\n        vec2 param_10 = _4534 + vec2(3.5, 10.5);\n        vec2 param_11 = _4534 + vec2(4.5, 10.5);\n        vec2 param_12 = _4534 + vec2(5.5, 10.5);\n        vec2 param_13 = _4534 + vec2(6.5, 10.5);\n        vec2 param_14 = _4534 + vec2(7.5, 10.5);\n        vec2 param_15 = _4534 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _4364)) + (fa_gi_fetch(param_9).xyz * _4368)) + (fa_gi_fetch(param_10).xyz * _4372)) + (fa_gi_fetch(param_11).xyz * _4379)) + (fa_gi_fetch(param_12).xyz * _4386)) + (fa_gi_fetch(param_13).xyz * _4395)) + (fa_gi_fetch(param_14).xyz * _4402)) + (fa_gi_fetch(param_15).xyz * _4415)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_4314 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _4770;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _4770 = _4267.x;\n    }\n    else\n    {\n        _4770 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_4262.w * _4770);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _4794 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _4799 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _4804 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _4804) && (k < 8); k++)\n    {\n        int param = _4799 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _4794;\n        vec3 _4829 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _4834 = param_3 * left;\n        acc += (_4829 * _4834);\n        left -= _4834;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _4863 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _4863;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3713;\n    if (fa_lm.z > 0.5)\n    {\n        _3713 = 0.0;\n    }\n    else\n    {\n        _3713 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _3724 = _3713 < 1.0;\n    bool _3730;\n    if (_3724)\n    {\n        int param = li;\n        _3730 = fa_light_baked(param);\n    }\n    else\n    {\n        _3730 = _3724;\n    }\n    return _3730 ? _3713 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _592 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _605 = (c - (ru * hx)) - p;\n        vec3 _611 = ru * (2.0 * hx);\n        float _617 = max(dot(_611, _611), 9.9999999392252902907785028219223e-09);\n        float _621 = dot(_605, _611);\n        float t = clamp((-_621) / _617, 0.0, 1.0);\n        if (_592)\n        {\n            float _636 = dot(r, _611);\n            float _642 = _617 - (_636 * _636);\n            if (abs(_642) > (9.9999997473787516355514526367188e-06 * _617))\n            {\n                t = clamp(((dot(r, _605) * _636) - _621) / _642, 0.0, 1.0);\n            }\n        }\n        return (p + _605) + (_611 * t);\n    }\n    vec3 q = p;\n    float _674 = dot(r, axis);\n    bool _682;\n    if (_592)\n    {\n        _682 = abs(_674) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _682 = _592;\n    }\n    if (_682)\n    {\n        float _692 = dot(c - p, axis) / _674;\n        if (_692 > 0.0)\n        {\n            q = p + (r * _692);\n        }\n    }\n    vec3 _705 = q - c;\n    vec2 xy = vec2(dot(_705, ru), dot(_705, uu));\n    if (shape > 0.5)\n    {\n        float _720 = length(xy);\n        if (_720 > hx)\n        {\n            xy *= (hx / _720);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _512 = dot(d, right);\n    float _516 = dot(d, up);\n    float _527;\n    if (((_512 * _512) + (_516 * _516)) > 1.0000000133514319600180897396058e-10)\n    {\n        _527 = atan(_516, _512) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _527 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_527 - floor(_527)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _362 = abs(d);\n    float _364 = _362.x;\n    float _366 = _362.y;\n    bool _367 = _364 >= _366;\n    bool _375;\n    if (_367)\n    {\n        _375 = _364 >= _362.z;\n    }\n    else\n    {\n        _375 = _367;\n    }\n    int _376;\n    if (_375)\n    {\n        _376 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _391;\n        if (_366 >= _362.z)\n        {\n            _391 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _391 = (d.z > 0.0) ? 4 : 5;\n        }\n        _376 = _391;\n    }\n    return _376;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _758 = fa_light_base(param);\n    bool _762 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _758;\n    vec4 _766 = fa_light_texel(param_1);\n    int param_2 = _758 + 1;\n    vec4 _771 = fa_light_texel(param_2);\n    float _774 = _771.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _786 = _762 && (_774 > 2.5);\n    fa_light_is_area = _786;\n    bool _788 = _774 < 0.5;\n    vec3 l;\n    if (_788)\n    {\n        l = normalize(_766.xyz);\n        if (_762)\n        {\n            int param_3 = _758 + 6;\n            vec4 _802 = fa_light_texel(param_3);\n            if (_802.z > 0.5)\n            {\n                int param_4 = _758 + 4;\n                vec4 _812 = fa_light_texel(param_4);\n                int param_5 = _758 + 5;\n                vec4 _817 = fa_light_texel(param_5);\n                vec2 param_6 = _802.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _812.xyz) * _812.w, (-dot(world_pos, _817.xyz)) * _817.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _847 = _766.xyz;\n        vec3 _849 = _847 - world_pos;\n        vec3 to_light = _849;\n        float _852 = length(_849);\n        float reach = _852;\n        bool front = true;\n        if (_786)\n        {\n            int param_8 = _758 + 7;\n            reach = max(_852 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _758 + 4;\n            vec4 _876 = fa_light_texel(param_9);\n            int param_10 = _758 + 5;\n            vec4 _881 = fa_light_texel(param_10);\n            int param_11 = _758 + 6;\n            vec4 _886 = fa_light_texel(param_11);\n            float _887 = _886.w;\n            int param_12 = _758 + 2;\n            vec3 _894 = normalize(fa_light_texel(param_12).xyz);\n            bool _896 = _887 > 1.5;\n            bool _904;\n            if (!_896)\n            {\n                _904 = dot(_894, to_light) < 0.0;\n            }\n            else\n            {\n                _904 = _896;\n            }\n            front = _904;\n            vec3 r = vec3(0.0);\n            vec3 _913 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _917 = dot(n, n) > 0.5;\n            bool _925;\n            if (_917)\n            {\n                _925 = dot(_913, _913) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _925 = _917;\n            }\n            if (_925)\n            {\n                r = reflect(-normalize(_913), normalize(n));\n            }\n            vec3 param_13 = _847;\n            vec3 param_14 = _894;\n            vec3 param_15 = _876.xyz;\n            vec3 param_16 = _881.xyz;\n            float param_17 = _876.w;\n            float param_18 = _881.w;\n            float param_19 = _887;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _961 = length(to_light);\n        dist = _961;\n        l = to_light / vec3(max(_961, 9.9999997473787516355514526367188e-05));\n        float _975 = reach / max(_766.w, 0.001000000047497451305389404296875);\n        float _981 = clamp(1.0 - (_975 * _975), 0.0, 1.0);\n        float _983;\n        if (front)\n        {\n            _983 = _981 * _981;\n        }\n        else\n        {\n            _983 = 0.0;\n        }\n        atten = _983;\n        bool _994 = _774 < 2.5;\n        if ((_774 > 1.5) && _994)\n        {\n            int param_22 = _758 + 2;\n            vec4 _1002 = fa_light_texel(param_22);\n            float _1012 = _1002.w;\n            int param_23 = _758 + 3;\n            vec4 _1017 = fa_light_texel(param_23);\n            float _1018 = _1017.x;\n            float cos_inner = _1018;\n            if (_1018 > 1.5)\n            {\n                cos_inner = mix(_1012, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1012, cos_inner, dot(-l, normalize(_1002.xyz)));\n        }\n        if (_762 && (_774 < 1.5))\n        {\n            int param_24 = _758 + 6;\n            vec4 _1042 = fa_light_texel(param_24);\n            if (_1042.z > 0.5)\n            {\n                vec3 _1050 = -to_light;\n                int param_25 = _758 + 4;\n                int param_26 = _758 + 5;\n                vec3 _1064 = fa_light_texel(param_25).xyz;\n                vec3 _1068 = fa_light_texel(param_26).xyz;\n                vec3 _1077 = vec3(dot(_1050, _1064), dot(_1050, _1068), dot(_1050, cross(_1064, _1068)));\n                vec3 param_27 = _1077;\n                int _1081 = fa_cube_face(param_27);\n                int param_28 = _1081;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1108 = vec2(dot(_1077, cross(param_29, param_30)), dot(_1077, param_30)) / vec2(max(dot(_1077, param_29), 9.9999997473787516355514526367188e-05));\n                int _1112 = _1081 / 3;\n                vec2 param_31 = _1042.xy + (vec2(float(_1081 - (_1112 * 3)), float(_1112)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1108.x), 0.5 - (0.5 * _1108.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _758 + 7;\n            vec4 _1142 = fa_light_texel(param_33);\n            if (_1142.z > 0.5)\n            {\n                int param_34 = _758 + 2;\n                int param_35 = _758 + 4;\n                int param_36 = _758 + 5;\n                vec2 param_37 = _1142.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_762 && _994)\n            {\n                int param_42 = _758 + 6;\n                vec4 _1189 = fa_light_texel(param_42);\n                int param_43 = _758 + 7;\n                vec4 _1194 = fa_light_texel(param_43);\n                bool _1197 = _1189.z > 0.5;\n                bool _1204;\n                if (!_1197)\n                {\n                    _1204 = _1194.z > 0.5;\n                }\n                else\n                {\n                    _1204 = _1197;\n                }\n                if (_1204)\n                {\n                    int param_44 = _758 + 2;\n                    vec4 _1211 = fa_light_texel(param_44);\n                    vec3 _1215 = normalize(_1211.xyz);\n                    int param_45 = _758 + 4;\n                    vec4 _1220 = fa_light_texel(param_45);\n                    int param_46 = _758 + 5;\n                    vec4 _1225 = fa_light_texel(param_46);\n                    if (_1197)\n                    {\n                        vec3 _1233 = -to_light;\n                        float _1240 = _1211.w;\n                        float _1256 = 0.5 / max(dot(_1233, _1215) * (sqrt(max(1.0 - (_1240 * _1240), 0.0)) / max(_1240, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1189.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1233, _1220.xyz) * _1256), 0.5 - (dot(_1233, _1225.xyz) * _1256));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1194.z > 0.5)\n                    {\n                        vec2 param_49 = _1194.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1215;\n                        vec3 param_52 = _1220.xyz;\n                        vec3 param_53 = _1225.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5550 = _771.xyz * atten;\n    if (_762)\n    {\n        _5550 *= fa_light_tint;\n    }\n    int _1324;\n    if (_788)\n    {\n        _1324 = 0;\n    }\n    else\n    {\n        _1324 = ((_774 > 1.5) && (_774 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5550, atten, 1.0, dist, _1324);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2113 = fa_shadow_depth(param, param_1);\n    float _2117;\n    if (conv.x < 0.5)\n    {\n        _2117 = _2113;\n    }\n    else\n    {\n        _2117 = (conv.y * conv.z) / (conv.z - (_2113 * (conv.z - conv.y)));\n    }\n    return _2117;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2163 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2169 = vec2(cos(_2163), sin(_2163));\n    vec2 dir = _2169;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2178;\n        if (k < 0.0)\n        {\n            _2178 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2178 = k;\n        }\n        float _2197 = clamp((_2178 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2216 = sqrt((float(i) + 0.5) * 0.0625) * _2197;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2216));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2230 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2230 < (zr - (_2216 * plane)))\n            {\n                sum += _2230;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2258 = sum / cnt;\n        float _2268;\n        if (k < 0.0)\n        {\n            _2268 = (-k) / max(_2258, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2268 = k;\n        }\n        radius = clamp(((max(zr - _2258, 0.0) * unit) * _2268) / texel_m, 1.5, 16.0);\n        dir = _2169;\n    }\n    float lit = 0.0;\n    int _2294 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2294; i_1++)\n    {\n        float _2313 = sqrt((float(i_1) + 0.5) / float(_2294)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2313));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2313 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2294);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2518 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2525;\n    if (!_2518)\n    {\n        _2525 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2525 = _2518;\n    }\n    if (_2525)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2538 = fa_light_texel(param);\n    float _2539 = _2538.x;\n    if (_2539 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2548 = int(_2539 + 0.5);\n    int param_1 = _2548;\n    vec4 _2552 = fa_light_texel(param_1);\n    int param_2 = _2548 + 1;\n    vec4 _2557 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2560 = _2552.y;\n    if (_2560 > 0.0)\n    {\n        float _2577 = 1.0 - smoothstep(0.75 * _2560, _2560, length(world - fa_shadows[27].xyz));\n        fade = _2577;\n        if (_2577 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2552.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2601 = (_2548 + 2) + (face * 6);\n    int param_4 = _2601;\n    int param_5 = _2601 + 1;\n    int param_6 = _2601 + 3;\n    vec4 _2615 = fa_light_texel(param_6);\n    int param_7 = _2601 + 4;\n    vec4 _2620 = fa_light_texel(param_7);\n    int param_8 = _2601 + 5;\n    vec4 _2625 = fa_light_texel(param_8);\n    float _2637 = _2625.x * max(dot(_2615, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2642 = clamp(dot(n, l), 0.0, 1.0);\n    float _2665 = clamp(dot(n, _2615.xyz), -1.0, 1.0);\n    float _2684 = min(sqrt(1.0 - (_2665 * _2665)) / max(abs(dot(n, world - lpos)) / max(dot(_2615, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2687 = _2557.y;\n    float _2689;\n    if (_2687 > 0.0)\n    {\n        _2689 = _2687;\n    }\n    else\n    {\n        _2689 = 1.5 * _2637;\n    }\n    vec4 _2709 = vec4(world + (n * (_2689 * sqrt(1.0 - (_2642 * _2642)))), 1.0);\n    float _2713 = dot(_2615, _2709);\n    float _2716 = _2625.y;\n    if (_2713 < _2716)\n    {\n        return 1.0;\n    }\n    vec2 _2731 = vec2(dot(fa_light_texel(param_4), _2709), dot(fa_light_texel(param_5), _2709)) / vec2(_2713);\n    float _2733 = _2731.x;\n    bool _2736 = _2733 < _2620.x;\n    bool _2745;\n    if (!_2736)\n    {\n        _2745 = _2733 > _2620.z;\n    }\n    else\n    {\n        _2745 = _2736;\n    }\n    bool _2754;\n    if (!_2745)\n    {\n        _2754 = _2731.y < _2620.y;\n    }\n    else\n    {\n        _2754 = _2745;\n    }\n    bool _2763;\n    if (!_2754)\n    {\n        _2763 = _2731.y > _2620.w;\n    }\n    else\n    {\n        _2763 = _2754;\n    }\n    if (_2763)\n    {\n        return 1.0;\n    }\n    float _2769 = _2557.x;\n    float _2771;\n    if (_2769 > 0.0)\n    {\n        _2771 = _2769;\n    }\n    else\n    {\n        _2771 = 1.5 * _2637;\n    }\n    vec2 param_9 = _2731;\n    vec4 param_10 = _2620;\n    float param_11 = _2713 - (_2771 * (1.0 + (0.5 * _2684)));\n    float param_12 = _2637;\n    float param_13 = 1.0;\n    float param_14 = _2625.z * 0.25;\n    float param_15 = (_2637 * min(_2684, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2716, _2625.z);\n    int param_17 = int(_2552.z + 0.5);\n    float param_18 = _2552.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2056;\n    if (i == 0)\n    {\n        _2056 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2072;\n        if (i == 1)\n        {\n            _2072 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2080;\n            if (i == 2)\n            {\n                _2080 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2080 = fa_shadows[24].w;\n            }\n            _2072 = _2080;\n        }\n        _2056 = _2072;\n    }\n    return _2056;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2359 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2364 = clamp(dot(n, l), 0.0, 1.0);\n    float _2370 = sqrt(1.0 - (_2364 * _2364));\n    float _2378 = min(_2370 / max(_2364, 0.20000000298023223876953125), 4.0);\n    float _2383;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2383 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2383 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2408 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2383 * _2370)), 1.0);\n    float _2415 = _2408.x;\n    bool _2418 = _2415 < fa_shadows[ci * 1 + 16].x;\n    bool _2427;\n    if (!_2418)\n    {\n        _2427 = _2415 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2427 = _2418;\n    }\n    bool _2436;\n    if (!_2427)\n    {\n        _2436 = _2408.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2436 = _2427;\n    }\n    bool _2445;\n    if (!_2436)\n    {\n        _2445 = _2408.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2445 = _2436;\n    }\n    bool _2452;\n    if (!_2445)\n    {\n        _2452 = _2408.z > 1.0;\n    }\n    else\n    {\n        _2452 = _2445;\n    }\n    if (_2452)\n    {\n        return -1.0;\n    }\n    float _2460;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2460 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2460 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2408.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2408.z - ((_2460 * (1.0 + (0.5 * _2378))) / _2359);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2359;\n    float param_5 = _2359 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2378, 3.0)) * 0.5) / _2359;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2838 = int(fa_shadows[25].x + 0.5);\n    if (_2838 < 1)\n    {\n        return 1.0;\n    }\n    float _2853 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2838 - 1;\n    if (_2853 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2865 = _2838 > 1;\n    bool _2872;\n    if (_2865)\n    {\n        _2872 = _2853 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2872 = _2865;\n    }\n    if (_2872)\n    {\n        ci = 1;\n    }\n    bool _2876 = _2838 > 2;\n    bool _2883;\n    if (_2876)\n    {\n        _2883 = _2853 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2883 = _2876;\n    }\n    if (_2883)\n    {\n        ci = 2;\n    }\n    bool _2887 = _2838 > 3;\n    bool _2894;\n    if (_2887)\n    {\n        _2894 = _2853 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2894 = _2887;\n    }\n    if (_2894)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2838)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2920 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2920;\n        if (_2920 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2945;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2945 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2945 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2964 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2945, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2975 = clamp((_2853 - (fa_shadow_split_at(param_7) - _2964)) / _2964, 0.0, 1.0);\n        if (_2975 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2838)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2996 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2996;\n                if (_2996 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2975);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3447 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3454;\n    if (!_3447)\n    {\n        _3454 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3454 = _3447;\n    }\n    if (_3454)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3467 = fa_light_texel(param);\n    float _3468 = _3467.y;\n    float len = _3468;\n    if (_3468 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3480 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3490 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3480);\n    if (_3490 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3496 = len;\n    float _3499 = min(_3496, 0.89999997615814208984375 * dist);\n    len = _3499;\n    float _3505 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3480);\n    float _3510 = _3505 + (0.5 * _3499);\n    vec3 _3516 = world + (gn * _3505);\n    float _3518 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3583;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3534 = (float(k) + _3518) * 0.083333335816860198974609375;\n        vec3 _3542 = _3516 + (l * (_3534 * len));\n        vec4 _3548 = vec4(_3542, 1.0);\n        float _3554 = dot(fa_mesh_fs_params[28], _3548);\n        if (_3554 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3574 = vec2(dot(fa_mesh_fs_params[26], _3548), dot(fa_mesh_fs_params[27], _3548)) / vec2(_3554);\n        float _3578 = _3574.x * 0.5;\n        float _3579 = _3578 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3583 = (_3574.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3583 = 0.5 - (_3574.y * 0.5);\n        }\n        bool _3599 = _3579 < 0.0;\n        bool _3606;\n        if (!_3599)\n        {\n            _3606 = _3579 >= 1.0;\n        }\n        else\n        {\n            _3606 = _3599;\n        }\n        bool _3613;\n        if (!_3606)\n        {\n            _3613 = _3583 < 0.0;\n        }\n        else\n        {\n            _3613 = _3606;\n        }\n        bool _3620;\n        if (!_3613)\n        {\n            _3620 = _3583 >= 1.0;\n        }\n        else\n        {\n            _3620 = _3613;\n        }\n        if (_3620)\n        {\n            break;\n        }\n        vec4 _3647 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3579, _3583) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_3647.w < 0.5)\n        {\n            continue;\n        }\n        float _3666 = (dot(fa_mesh_fs_params[29].xyz, _3542) + fa_mesh_fs_params[29].w) - _3647.x;\n        if ((_3666 > _3505) && (_3666 < _3510))\n        {\n            occ = max(occ, (1.0 - (_3534 * _3534)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3579, 0.5 - _3578), min(_3583, 1.0 - _3583))));\n        }\n    }\n    return 1.0 - (occ * _3490);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _3769 = fa_baked_keep(param);\n    if (_3769 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3795 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _5576 = _3795.color;\n    float _5577 = _3795.attenuation;\n    float _5578 = _3795.shadow;\n    bool _3798 = _3795.type == 0;\n    if (_3798 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3795.direction;\n        float _3809 = fa_shadow_factor(param_5, param_6);\n        _5578 = _3809;\n        _5576 *= _3809;\n    }\n    else\n    {\n        bool _3820 = _3795.type != 0;\n        bool _3826;\n        if (_3820)\n        {\n            _3826 = _5577 > 0.0;\n        }\n        else\n        {\n            _3826 = _3820;\n        }\n        if (_3826)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3795.direction;\n            float _3845 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5578 = _3845;\n            _5576 *= _3845;\n        }\n    }\n    bool _3855 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3861;\n    if (_3855)\n    {\n        _3861 = _5577 > 0.0;\n    }\n    else\n    {\n        _3861 = _3855;\n    }\n    if (_3861)\n    {\n        float _3868;\n        if (_3798)\n        {\n            _3868 = 1000000000.0;\n        }\n        else\n        {\n            _3868 = _3795._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _3795.direction;\n        float param_18 = _3868;\n        float _3886 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5578 *= _3886;\n        _5576 *= _3886;\n    }\n    float _3899 = _5577;\n    float _3900 = _3899 * _3769;\n    _5577 = _3900;\n    vec3 _3904 = _5576;\n    vec3 _3905 = _3904 * _3769;\n    _5576 = _3905;\n    return LightSample(_3795.direction, _3905, _3900, _5578, _3795._distance, _3795.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3020 = int(fa_shadows[25].x + 0.5);\n    float _3030 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3035 = _3020 > 0;\n    bool _3044;\n    if (_3035)\n    {\n        int param = _3020 - 1;\n        _3044 = _3030 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3044 = _3035;\n    }\n    if (_3044)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3050 = _3020 > 1;\n        bool _3057;\n        if (_3050)\n        {\n            _3057 = _3030 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3057 = _3050;\n        }\n        if (_3057)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3063 = _3020 > 2;\n        bool _3070;\n        if (_3063)\n        {\n            _3070 = _3030 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3070 = _3063;\n        }\n        if (_3070)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3076 = _3020 > 3;\n        bool _3083;\n        if (_3076)\n        {\n            _3083 = _3030 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3083 = _3076;\n        }\n        if (_3083)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5397 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5397 = -_5397;\n    }\n    vec3 _4971 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5397, fa_world_tangent, fa_uv, fa_vertex_color, _4971, gl_FrontFacing);\n    Surface _4979 = fa_standard_surface(param_1);\n    vec3 _5428 = _4979.albedo;\n    float _5429 = _4979.alpha;\n    vec3 _5430 = _4979.normal;\n    float _5431 = _4979.metallic;\n    float _5432 = _4979.roughness;\n    float _5433 = _4979.occlusion;\n    vec3 _5434 = _4979.emission;\n    float _5435 = _4979.clearcoat;\n    float _5436 = _4979.clearcoat_roughness;\n    vec3 _5437 = _4979.sheen_color;\n    float _5438 = _4979.sheen_roughness;\n    float _5439 = _4979.anisotropy;\n    float _5440 = _4979.anisotropy_rotation;\n    float _5441 = _4979.specular;\n    float _5442 = _4979.ior;\n    vec3 _5443 = _4979.specular_color;\n    float _5444 = _4979.transmission;\n    float _5445 = _4979.thickness;\n    vec3 _5446 = _4979.attenuation_color;\n    float _5447 = _4979.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5397, fa_world_tangent, fa_uv, fa_vertex_color, _4971, gl_FrontFacing);\n    Surface param_3 = _4979;\n    surface(param_2, param_3);\n    _5428 = param_3.albedo;\n    _5429 = param_3.alpha;\n    _5430 = param_3.normal;\n    _5431 = param_3.metallic;\n    _5432 = param_3.roughness;\n    _5433 = param_3.occlusion;\n    _5434 = param_3.emission;\n    _5435 = param_3.clearcoat;\n    _5436 = param_3.clearcoat_roughness;\n    _5437 = param_3.sheen_color;\n    _5438 = param_3.sheen_roughness;\n    _5439 = param_3.anisotropy;\n    _5440 = param_3.anisotropy_rotation;\n    _5441 = param_3.specular;\n    _5442 = param_3.ior;\n    _5443 = param_3.specular_color;\n    _5444 = param_3.transmission;\n    _5445 = param_3.thickness;\n    _5446 = param_3.attenuation_color;\n    _5447 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5397;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5428 = param_6;\n    _5430 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5428;\n    }\n    else\n    {\n        vec3 _5018 = _5430;\n        vec3 _5019 = normalize(_5018);\n        _5430 = _5019;\n        vec3 param_8 = _5019;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _5428) * _5433;\n        int _5038 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5038; ln++)\n        {\n            int param_9 = ln;\n            int _5051 = fa_cl_light(param_9);\n            int param_10 = _5051;\n            if (fa_baked_keep(param_10) <= 0.0)\n            {\n                continue;\n            }\n            int param_11 = _5051;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _5397;\n            LightSample _5067 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _5397, fa_world_tangent, fa_uv, fa_vertex_color, _4971, gl_FrontFacing);\n            Surface param_15 = Surface(_5428, _5429, _5430, _5431, _5432, _5433, _5434, _5435, _5436, _5437, _5438, _5439, _5440, _5441, _5442, _5443, _5444, _5445, _5446, _5447);\n            LightSample param_16 = _5067;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _5082 = result;\n    vec3 _5083 = _5082 + _5434;\n    result = _5083;\n    vec3 param_17 = _5083;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _5092 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5099;\n    if (!_5092)\n    {\n        _5099 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5099 = _5092;\n    }\n    if (_5099)\n    {\n        vec3 _5108 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5114 = dot(_5108, fa_mesh_fs_params[9].xyz);\n        bool _5118 = fa_mesh_fs_params[9].w > 0.5;\n        float _5119;\n        if (_5118)\n        {\n            _5119 = _5114;\n        }\n        else\n        {\n            _5119 = length(_5108);\n        }\n        float _5131 = _5119 - fa_mesh_fs_params[8].x;\n        if (_5131 > 0.0)\n        {\n            float _5140 = fa_mesh_fs_params[7].w * _5131;\n            float tau = _5140 * _5140;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5156;\n                if (_5118)\n                {\n                    _5156 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5114);\n                }\n                else\n                {\n                    _5156 = fa_mesh_fs_params[0].y;\n                }\n                float _5177 = mix(_5156, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5119, 0.0, 1.0));\n                float _5181 = fa_world_pos.y - _5177;\n                float _5186 = _5177 - fa_mesh_fs_params[8].z;\n                float _5191 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5194 = _5186 <= 0.0;\n                bool _5195 = !_5194;\n                bool _5201;\n                if (_5195)\n                {\n                    _5201 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5201 = _5194;\n                }\n                float _5202;\n                if (_5201)\n                {\n                    _5202 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5202 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5186, 80.0));\n                }\n                bool _5229;\n                if (_5195)\n                {\n                    _5229 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5229 = _5194;\n                }\n                float _5230;\n                if (_5229)\n                {\n                    _5230 = fa_mesh_fs_params[8].y * _5186;\n                }\n                else\n                {\n                    _5230 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5186, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5255 = _5191 <= 0.0;\n                bool _5262;\n                if (!_5255)\n                {\n                    _5262 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5262 = _5255;\n                }\n                float _5263;\n                if (_5262)\n                {\n                    _5263 = fa_mesh_fs_params[8].y * _5191;\n                }\n                else\n                {\n                    _5263 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5191, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5290;\n                if (abs(_5181) < 0.001000000047497451305389404296875)\n                {\n                    _5290 = _5202;\n                }\n                else\n                {\n                    _5290 = (_5263 - _5230) / _5181;\n                }\n                tau += (_5131 * max(_5290, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5429);\n}\n\n",
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
            "inst_name": "_414",
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
            "inst_name": "_2066",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1342 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1349;\n    if (!_1342)\n    {\n        _1349 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1349 = _1342;\n    }\n    bool _1357;\n    if (!_1349)\n    {\n        _1357 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1357 = _1349;\n    }\n    bool _1364;\n    if (!_1357)\n    {\n        _1364 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1364 = _1357;\n    }\n    bool _1371;\n    if (!_1364)\n    {\n        _1371 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1371 = _1364;\n    }\n    if (_1371)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1381 = vec4(world_pos, 1.0);\n    float _1387 = dot(fa_mesh_fs_params[16], _1381);\n    if (!(_1387 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1409 = vec2(dot(fa_mesh_fs_params[14], _1381), dot(fa_mesh_fs_params[15], _1381)) / vec2(_1387);\n    int _1413 = int(fa_mesh_fs_params[18].x);\n    int _1417 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1417) + clamp(int(floor(((_1409.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1417 - 1)) * _1413)) + clamp(int(floor(((_1409.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1413 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1493 = fa_cluster_texel(param);\n    return ivec2(int(_1493.x), int(_1493.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3743 = fa_cluster_lookup(param);\n    fa_cl_slot = _3743.x;\n    fa_cl_local = _3743.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3948 = fa_linear_to_srgb(param);\n        c = _3948;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3956 = fa_srgb_to_linear(param_1);\n            c = _3956;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _296;\n    if (i.front_facing)\n    {\n        _296 = i.world_normal;\n    }\n    else\n    {\n        _296 = -i.world_normal;\n    }\n    vec3 _320 = normalize(i.world_tangent.xyz - (_296 * dot(_296, i.world_tangent.xyz)));\n    vec3 _347 = normalize(((_320 * m.x) + ((cross(_296, _320) * i.world_tangent.w) * m.y)) + (_296 * m.z));\n    vec3 _350;\n    if (i.front_facing)\n    {\n        _350 = _347;\n    }\n    else\n    {\n        _350 = -_347;\n    }\n    return _350;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3987 = fa_tex_fix(param_2, param_3);\n    vec4 _5759 = base_t;\n    _5759.x = _3987.x;\n    _5759.y = _3987.y;\n    _5759.z = _3987.z;\n    base_t = _5759;\n    vec4 _4001 = (_5759 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5596 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4033 = fa_tex_fix(param_6, param_7);\n        vec3 _4036 = (_4033 * 2.0) - vec3(1.0);\n        vec2 _4041 = _4036.xy * fa_mesh_fs_params[6].x;\n        vec3 _5767 = _4036;\n        _5767.x = _4041.x;\n        _5767.y = _4041.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5767;\n        _5596 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4069 = fa_tex_fix(param_12, param_13);\n    vec4 _5770 = mrt;\n    _5770.x = _4069.x;\n    _5770.y = _4069.y;\n    _5770.z = _4069.z;\n    mrt = _5770;\n    vec4 _4097 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4097.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4108 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4138 = fa_tex_fix(param_20, param_21);\n    float _5601 = fa_mesh_fs_params[20].x;\n    float _5602 = fa_mesh_fs_params[20].y;\n    float _5605 = fa_mesh_fs_params[20].z;\n    float _5604 = fa_mesh_fs_params[21].w;\n    float _5607 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5601 *= _4108.y;\n            _5602 *= _4108.z;\n            _5604 *= _4097.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5605 *= mrt.x;\n            _5607 *= mrt.w;\n        }\n    }\n    return Surface(_4001.xyz, _4001.w, _5596, clamp(fa_mesh_fs_params[5].x * _4069.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4069.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4108.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4138), _5601, _5602, fa_mesh_fs_params[21].xyz, _5604, _5605, fa_mesh_fs_params[20].w, _5607, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1573 = rect.zw - rect.xy;\n    vec2 _1577 = _1573 * atlas;\n    vec2 _1581 = ddx * _1577;\n    vec2 _1585 = ddy * _1577;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1573), clamp(0.5 * log2(max(max(dot(_1581, _1581), dot(_1585, _1585)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1618 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1625;\n    if (!_1618)\n    {\n        _1625 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1625 = _1618;\n    }\n    if (_1625)\n    {\n        return;\n    }\n    vec3 _1631 = dFdx(world_pos);\n    vec3 _1634 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1638 = fa_cluster_texel(param);\n    int _1642 = int(_1638.w);\n    if (_1642 < 1)\n    {\n        return;\n    }\n    int _1652 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1652;\n    vec4 _1656 = fa_light_texel(param_1);\n    vec2 _1659 = _1656.yz;\n    int _1663 = int(_1656.w);\n    int param_2 = _1652 + 1;\n    vec4 _1668 = fa_light_texel(param_2);\n    float _1669 = _1668.x;\n    int _1675 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1679 = int(_1638.z);\n    vec3 _1944;\n    for (int k = 0; k < _1642; k++)\n    {\n        int _1692 = _1679 + k;\n        int param_3 = _1663 + (_1692 >> 2);\n        int _1709 = (_1652 + 2) + (int(fa_light_texel(param_3)[_1692 & 3]) * 7);\n        int param_4 = _1709 + 6;\n        vec4 _1714 = fa_light_texel(param_4);\n        if (((int(_1714.w + 0.5) >> _1675) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1709;\n        vec4 _1729 = fa_light_texel(param_5);\n        int param_6 = _1709 + 1;\n        vec4 _1734 = fa_light_texel(param_6);\n        int param_7 = _1709 + 2;\n        vec4 _1739 = fa_light_texel(param_7);\n        vec3 _1742 = _1729.xyz;\n        float _1747 = dot(_1742, world_pos) + _1729.w;\n        vec3 _1749 = _1734.xyz;\n        float _1754 = dot(_1749, world_pos) + _1734.w;\n        vec3 _1756 = _1739.xyz;\n        float _1761 = dot(_1756, world_pos) + _1739.w;\n        bool _1766 = abs(_1747) > 0.5;\n        bool _1774;\n        if (!_1766)\n        {\n            _1774 = abs(_1754) > 0.5;\n        }\n        else\n        {\n            _1774 = _1766;\n        }\n        bool _1782;\n        if (!_1774)\n        {\n            _1782 = abs(_1761) > 0.5;\n        }\n        else\n        {\n            _1782 = _1774;\n        }\n        if (_1782)\n        {\n            continue;\n        }\n        float _1797 = clamp(dot(geo_normal, normalize(_1756)) * _1714.z, 0.0, 1.0);\n        if (_1797 <= 0.0)\n        {\n            continue;\n        }\n        float _1817 = (clamp((0.5 - abs(_1761)) * 10.0, 0.0, 1.0) * _1797) * _1714.x;\n        vec2 _1825 = vec2(_1747 + 0.5, 0.5 - _1754);\n        vec2 _1835 = vec2(dot(_1742, _1631), dot(_1749, _1631));\n        vec2 _1845 = vec2(dot(_1742, _1634), dot(_1749, _1634));\n        int param_8 = _1709 + 5;\n        vec4 _1850 = fa_light_texel(param_8);\n        int param_9 = _1709 + 3;\n        vec4 _1855 = fa_light_texel(param_9);\n        int param_10 = _1709 + 4;\n        vec4 _1860 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1850.xyz;\n        bool _1870 = _1855.z > _1855.x;\n        if (_1870)\n        {\n            vec4 param_11 = _1855;\n            vec2 param_12 = _1825;\n            vec2 param_13 = _1659;\n            vec2 param_14 = _1835;\n            vec2 param_15 = _1845;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1669 > 0.5) && (_1669 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1896 = fa_dc_to_linear(param_16);\n                vec4 _5684 = tx;\n                _5684.x = _1896.x;\n                _5684.y = _1896.y;\n                _5684.z = _1896.z;\n                tx = _5684;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1817 * tex_a) * _1850.w, 0.0, 1.0)));\n        if (_1860.z > _1860.x)\n        {\n            vec4 param_17 = _1860;\n            vec2 param_18 = _1825;\n            vec2 param_19 = _1659;\n            vec2 param_20 = _1835;\n            vec2 param_21 = _1845;\n            vec4 _1940 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1669 > 1.5)\n            {\n                vec3 param_22 = _1940.xyz;\n                vec3 _1950 = fa_dc_to_srgb(param_22);\n                _1944 = _1950;\n            }\n            else\n            {\n                _1944 = _1940.xyz;\n            }\n            vec3 _1959 = (_1944 * 2.0) - vec3(1.0);\n            vec2 _1964 = _1959.xy * _1714.y;\n            vec3 _1986 = (normalize(_1742) * _1964.x) + (normalize(_1749) * _1964.y);\n            vec3 _1989 = normalize(normal);\n            normal = normalize(mix(_1989, normalize((_1989 * max(_1959.z, 0.0500000007450580596923828125)) + (_1986 - (_1989 * dot(_1989, _1986)))), vec3(clamp(_1817 * (_1870 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3197 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3197;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3307 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3313 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3307 > 0.0005000000237487256526947021484375)\n    {\n        if (_3313)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3307;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3307;\n        }\n    }\n    bool _3365 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3365)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3396 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3396)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3313 || _3365) || _3396)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3217 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3220 = _3217.x;\n    float _3222 = _3217.z;\n    vec2 e = vec2(_3220, _3222);\n    if (_3217.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3222)) * ((_3220 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3220)) * ((_3222 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _4252 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _4257 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _4262 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _4267 = fa_light_texel(param_3);\n    bool _4270 = _4267.z < 0.5;\n    bool _4278;\n    if (!_4270)\n    {\n        _4278 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _4278 = _4270;\n    }\n    if (_4278)\n    {\n        return vec3(0.0);\n    }\n    float _4285 = max(_4252.w, 9.9999997473787516355514526367188e-05);\n    vec3 _4288 = _4257.xyz;\n    vec3 _4292 = _4252.xyz;\n    vec3 _4296 = (fa_world_pos - _4292) / vec3(_4285);\n    vec3 _4305 = min(_4296 + vec3(0.5), (_4288 - vec3(0.5)) - _4296);\n    float _4314 = min(_4305.x, min(_4305.y, _4305.z));\n    if (!(_4314 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4329 = _4288 - vec3(1.0);\n    vec3 _4330 = clamp(_4296, vec3(0.0), _4329);\n    vec3 _4338 = min(floor(_4330), max(_4288 - vec3(2.0), vec3(0.0)));\n    vec3 _4342 = _4330 - _4338;\n    vec3 _4354 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _4285));\n    int _4359 = int(_4262.y + 0.5);\n    float _4364 = 0.3257350027561187744140625 * n.y;\n    float _4368 = 0.3257350027561187744140625 * n.z;\n    float _4372 = 0.3257350027561187744140625 * n.x;\n    float _4379 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _4386 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _4395 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _4402 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _4415 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _4422 = 8 + int(_4267.w);\n    float _4449;\n    float _4462;\n    float _4476;\n    for (int k = 0; k < _4422; k++)\n    {\n        float _4435 = float(k & 1);\n        float _4439 = float((k >> 1) & 1);\n        float _4443 = float((k >> 2) & 1);\n        if (_4435 > 0.5)\n        {\n            _4449 = _4342.x;\n        }\n        else\n        {\n            _4449 = 1.0 - _4342.x;\n        }\n        if (_4439 > 0.5)\n        {\n            _4462 = _4342.y;\n        }\n        else\n        {\n            _4462 = 1.0 - _4342.y;\n        }\n        if (_4443 > 0.5)\n        {\n            _4476 = _4342.z;\n        }\n        else\n        {\n            _4476 = 1.0 - _4342.z;\n        }\n        float _4486 = (_4449 * _4462) * _4476;\n        if (!(_4486 > 0.0))\n        {\n            continue;\n        }\n        vec3 _4499 = min(_4338 + vec3(_4435, _4439, _4443), _4329);\n        int _4519 = int(((_4262.x + _4499.x) + (_4257.x * (_4499.y + (_4257.y * _4499.z)))) + 0.5);\n        vec2 _4534 = vec2(float(_4519 % _4359) * 10.0, 1024.0 + (float(_4519 / _4359) * 11.0));\n        vec2 param_4 = _4534 + vec2(9.5, 10.5);\n        vec4 _4542 = fa_gi_fetch(param_4);\n        bool _4545 = _4542.y < 0.5;\n        bool _4554;\n        if (!_4545)\n        {\n            _4554 = _4542.x > _4267.y;\n        }\n        else\n        {\n            _4554 = _4545;\n        }\n        if (_4554)\n        {\n            continue;\n        }\n        vec3 _4566 = _4354 - (_4292 + (_4499 * _4285));\n        float _4569 = length(_4566);\n        vec3 _4575 = _4566 / vec3(max(_4569, 9.9999997473787516355514526367188e-05));\n        float _4585 = max(9.9999997473787516355514526367188e-05, (dot(-_4575, n) + 1.0) * 0.5);\n        float w = _4486 * (_4585 * _4585);\n        vec3 param_5 = _4575;\n        vec2 param_6 = (_4534 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _4605 = fa_gi_fetch(param_6);\n        float _4612 = _4569 / max(_4262.z, 9.9999997473787516355514526367188e-05);\n        float _4615 = _4605.x;\n        if (_4612 > _4615)\n        {\n            float _4628 = max(_4605.y - (_4615 * _4615), 0.0);\n            float _4633 = _4612 - _4615;\n            float _4642 = _4628 / max(_4628 + (_4633 * _4633), 9.9999999600419720025001879548654e-13);\n            w *= ((_4642 * _4642) * _4642);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _4534 + vec2(0.5, 10.5);\n        vec2 param_8 = _4534 + vec2(1.5, 10.5);\n        vec2 param_9 = _4534 + vec2(2.5, 10.5);\n        vec2 param_10 = _4534 + vec2(3.5, 10.5);\n        vec2 param_11 = _4534 + vec2(4.5, 10.5);\n        vec2 param_12 = _4534 + vec2(5.5, 10.5);\n        vec2 param_13 = _4534 + vec2(6.5, 10.5);\n        vec2 param_14 = _4534 + vec2(7.5, 10.5);\n        vec2 param_15 = _4534 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _4364)) + (fa_gi_fetch(param_9).xyz * _4368)) + (fa_gi_fetch(param_10).xyz * _4372)) + (fa_gi_fetch(param_11).xyz * _4379)) + (fa_gi_fetch(param_12).xyz * _4386)) + (fa_gi_fetch(param_13).xyz * _4395)) + (fa_gi_fetch(param_14).xyz * _4402)) + (fa_gi_fetch(param_15).xyz * _4415)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_4314 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _4770;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _4770 = _4267.x;\n    }\n    else\n    {\n        _4770 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_4262.w * _4770);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _4794 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _4799 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _4804 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _4804) && (k < 8); k++)\n    {\n        int param = _4799 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _4794;\n        vec3 _4829 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _4834 = param_3 * left;\n        acc += (_4829 * _4834);\n        left -= _4834;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _4863 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _4863;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3713;\n    if (fa_lm.z > 0.5)\n    {\n        _3713 = 0.0;\n    }\n    else\n    {\n        _3713 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _3724 = _3713 < 1.0;\n    bool _3730;\n    if (_3724)\n    {\n        int param = li;\n        _3730 = fa_light_baked(param);\n    }\n    else\n    {\n        _3730 = _3724;\n    }\n    return _3730 ? _3713 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _592 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _605 = (c - (ru * hx)) - p;\n        vec3 _611 = ru * (2.0 * hx);\n        float _617 = max(dot(_611, _611), 9.9999999392252902907785028219223e-09);\n        float _621 = dot(_605, _611);\n        float t = clamp((-_621) / _617, 0.0, 1.0);\n        if (_592)\n        {\n            float _636 = dot(r, _611);\n            float _642 = _617 - (_636 * _636);\n            if (abs(_642) > (9.9999997473787516355514526367188e-06 * _617))\n            {\n                t = clamp(((dot(r, _605) * _636) - _621) / _642, 0.0, 1.0);\n            }\n        }\n        return (p + _605) + (_611 * t);\n    }\n    vec3 q = p;\n    float _674 = dot(r, axis);\n    bool _682;\n    if (_592)\n    {\n        _682 = abs(_674) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _682 = _592;\n    }\n    if (_682)\n    {\n        float _692 = dot(c - p, axis) / _674;\n        if (_692 > 0.0)\n        {\n            q = p + (r * _692);\n        }\n    }\n    vec3 _705 = q - c;\n    vec2 xy = vec2(dot(_705, ru), dot(_705, uu));\n    if (shape > 0.5)\n    {\n        float _720 = length(xy);\n        if (_720 > hx)\n        {\n            xy *= (hx / _720);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _512 = dot(d, right);\n    float _516 = dot(d, up);\n    float _527;\n    if (((_512 * _512) + (_516 * _516)) > 1.0000000133514319600180897396058e-10)\n    {\n        _527 = atan(_516, _512) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _527 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_527 - floor(_527)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _362 = abs(d);\n    float _364 = _362.x;\n    float _366 = _362.y;\n    bool _367 = _364 >= _366;\n    bool _375;\n    if (_367)\n    {\n        _375 = _364 >= _362.z;\n    }\n    else\n    {\n        _375 = _367;\n    }\n    int _376;\n    if (_375)\n    {\n        _376 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _391;\n        if (_366 >= _362.z)\n        {\n            _391 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _391 = (d.z > 0.0) ? 4 : 5;\n        }\n        _376 = _391;\n    }\n    return _376;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _758 = fa_light_base(param);\n    bool _762 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _758;\n    vec4 _766 = fa_light_texel(param_1);\n    int param_2 = _758 + 1;\n    vec4 _771 = fa_light_texel(param_2);\n    float _774 = _771.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _786 = _762 && (_774 > 2.5);\n    fa_light_is_area = _786;\n    bool _788 = _774 < 0.5;\n    vec3 l;\n    if (_788)\n    {\n        l = normalize(_766.xyz);\n        if (_762)\n        {\n            int param_3 = _758 + 6;\n            vec4 _802 = fa_light_texel(param_3);\n            if (_802.z > 0.5)\n            {\n                int param_4 = _758 + 4;\n                vec4 _812 = fa_light_texel(param_4);\n                int param_5 = _758 + 5;\n                vec4 _817 = fa_light_texel(param_5);\n                vec2 param_6 = _802.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _812.xyz) * _812.w, (-dot(world_pos, _817.xyz)) * _817.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _847 = _766.xyz;\n        vec3 _849 = _847 - world_pos;\n        vec3 to_light = _849;\n        float _852 = length(_849);\n        float reach = _852;\n        bool front = true;\n        if (_786)\n        {\n            int param_8 = _758 + 7;\n            reach = max(_852 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _758 + 4;\n            vec4 _876 = fa_light_texel(param_9);\n            int param_10 = _758 + 5;\n            vec4 _881 = fa_light_texel(param_10);\n            int param_11 = _758 + 6;\n            vec4 _886 = fa_light_texel(param_11);\n            float _887 = _886.w;\n            int param_12 = _758 + 2;\n            vec3 _894 = normalize(fa_light_texel(param_12).xyz);\n            bool _896 = _887 > 1.5;\n            bool _904;\n            if (!_896)\n            {\n                _904 = dot(_894, to_light) < 0.0;\n            }\n            else\n            {\n                _904 = _896;\n            }\n            front = _904;\n            vec3 r = vec3(0.0);\n            vec3 _913 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _917 = dot(n, n) > 0.5;\n            bool _925;\n            if (_917)\n            {\n                _925 = dot(_913, _913) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _925 = _917;\n            }\n            if (_925)\n            {\n                r = reflect(-normalize(_913), normalize(n));\n            }\n            vec3 param_13 = _847;\n            vec3 param_14 = _894;\n            vec3 param_15 = _876.xyz;\n            vec3 param_16 = _881.xyz;\n            float param_17 = _876.w;\n            float param_18 = _881.w;\n            float param_19 = _887;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _961 = length(to_light);\n        dist = _961;\n        l = to_light / vec3(max(_961, 9.9999997473787516355514526367188e-05));\n        float _975 = reach / max(_766.w, 0.001000000047497451305389404296875);\n        float _981 = clamp(1.0 - (_975 * _975), 0.0, 1.0);\n        float _983;\n        if (front)\n        {\n            _983 = _981 * _981;\n        }\n        else\n        {\n            _983 = 0.0;\n        }\n        atten = _983;\n        bool _994 = _774 < 2.5;\n        if ((_774 > 1.5) && _994)\n        {\n            int param_22 = _758 + 2;\n            vec4 _1002 = fa_light_texel(param_22);\n            float _1012 = _1002.w;\n            int param_23 = _758 + 3;\n            vec4 _1017 = fa_light_texel(param_23);\n            float _1018 = _1017.x;\n            float cos_inner = _1018;\n            if (_1018 > 1.5)\n            {\n                cos_inner = mix(_1012, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1012, cos_inner, dot(-l, normalize(_1002.xyz)));\n        }\n        if (_762 && (_774 < 1.5))\n        {\n            int param_24 = _758 + 6;\n            vec4 _1042 = fa_light_texel(param_24);\n            if (_1042.z > 0.5)\n            {\n                vec3 _1050 = -to_light;\n                int param_25 = _758 + 4;\n                int param_26 = _758 + 5;\n                vec3 _1064 = fa_light_texel(param_25).xyz;\n                vec3 _1068 = fa_light_texel(param_26).xyz;\n                vec3 _1077 = vec3(dot(_1050, _1064), dot(_1050, _1068), dot(_1050, cross(_1064, _1068)));\n                vec3 param_27 = _1077;\n                int _1081 = fa_cube_face(param_27);\n                int param_28 = _1081;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1108 = vec2(dot(_1077, cross(param_29, param_30)), dot(_1077, param_30)) / vec2(max(dot(_1077, param_29), 9.9999997473787516355514526367188e-05));\n                int _1112 = _1081 / 3;\n                vec2 param_31 = _1042.xy + (vec2(float(_1081 - (_1112 * 3)), float(_1112)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1108.x), 0.5 - (0.5 * _1108.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _758 + 7;\n            vec4 _1142 = fa_light_texel(param_33);\n            if (_1142.z > 0.5)\n            {\n                int param_34 = _758 + 2;\n                int param_35 = _758 + 4;\n                int param_36 = _758 + 5;\n                vec2 param_37 = _1142.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_762 && _994)\n            {\n                int param_42 = _758 + 6;\n                vec4 _1189 = fa_light_texel(param_42);\n                int param_43 = _758 + 7;\n                vec4 _1194 = fa_light_texel(param_43);\n                bool _1197 = _1189.z > 0.5;\n                bool _1204;\n                if (!_1197)\n                {\n                    _1204 = _1194.z > 0.5;\n                }\n                else\n                {\n                    _1204 = _1197;\n                }\n                if (_1204)\n                {\n                    int param_44 = _758 + 2;\n                    vec4 _1211 = fa_light_texel(param_44);\n                    vec3 _1215 = normalize(_1211.xyz);\n                    int param_45 = _758 + 4;\n                    vec4 _1220 = fa_light_texel(param_45);\n                    int param_46 = _758 + 5;\n                    vec4 _1225 = fa_light_texel(param_46);\n                    if (_1197)\n                    {\n                        vec3 _1233 = -to_light;\n                        float _1240 = _1211.w;\n                        float _1256 = 0.5 / max(dot(_1233, _1215) * (sqrt(max(1.0 - (_1240 * _1240), 0.0)) / max(_1240, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1189.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1233, _1220.xyz) * _1256), 0.5 - (dot(_1233, _1225.xyz) * _1256));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1194.z > 0.5)\n                    {\n                        vec2 param_49 = _1194.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1215;\n                        vec3 param_52 = _1220.xyz;\n                        vec3 param_53 = _1225.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5550 = _771.xyz * atten;\n    if (_762)\n    {\n        _5550 *= fa_light_tint;\n    }\n    int _1324;\n    if (_788)\n    {\n        _1324 = 0;\n    }\n    else\n    {\n        _1324 = ((_774 > 1.5) && (_774 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5550, atten, 1.0, dist, _1324);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2113 = fa_shadow_depth(param, param_1);\n    float _2117;\n    if (conv.x < 0.5)\n    {\n        _2117 = _2113;\n    }\n    else\n    {\n        _2117 = (conv.y * conv.z) / (conv.z - (_2113 * (conv.z - conv.y)));\n    }\n    return _2117;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2163 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2169 = vec2(cos(_2163), sin(_2163));\n    vec2 dir = _2169;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2178;\n        if (k < 0.0)\n        {\n            _2178 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2178 = k;\n        }\n        float _2197 = clamp((_2178 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2216 = sqrt((float(i) + 0.5) * 0.0625) * _2197;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2216));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2230 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2230 < (zr - (_2216 * plane)))\n            {\n                sum += _2230;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2258 = sum / cnt;\n        float _2268;\n        if (k < 0.0)\n        {\n            _2268 = (-k) / max(_2258, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2268 = k;\n        }\n        radius = clamp(((max(zr - _2258, 0.0) * unit) * _2268) / texel_m, 1.5, 16.0);\n        dir = _2169;\n    }\n    float lit = 0.0;\n    int _2294 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2294; i_1++)\n    {\n        float _2313 = sqrt((float(i_1) + 0.5) / float(_2294)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2313));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2313 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2294);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2518 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2525;\n    if (!_2518)\n    {\n        _2525 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2525 = _2518;\n    }\n    if (_2525)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2538 = fa_light_texel(param);\n    float _2539 = _2538.x;\n    if (_2539 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2548 = int(_2539 + 0.5);\n    int param_1 = _2548;\n    vec4 _2552 = fa_light_texel(param_1);\n    int param_2 = _2548 + 1;\n    vec4 _2557 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2560 = _2552.y;\n    if (_2560 > 0.0)\n    {\n        float _2577 = 1.0 - smoothstep(0.75 * _2560, _2560, length(world - fa_shadows[27].xyz));\n        fade = _2577;\n        if (_2577 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2552.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2601 = (_2548 + 2) + (face * 6);\n    int param_4 = _2601;\n    int param_5 = _2601 + 1;\n    int param_6 = _2601 + 3;\n    vec4 _2615 = fa_light_texel(param_6);\n    int param_7 = _2601 + 4;\n    vec4 _2620 = fa_light_texel(param_7);\n    int param_8 = _2601 + 5;\n    vec4 _2625 = fa_light_texel(param_8);\n    float _2637 = _2625.x * max(dot(_2615, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2642 = clamp(dot(n, l), 0.0, 1.0);\n    float _2665 = clamp(dot(n, _2615.xyz), -1.0, 1.0);\n    float _2684 = min(sqrt(1.0 - (_2665 * _2665)) / max(abs(dot(n, world - lpos)) / max(dot(_2615, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2687 = _2557.y;\n    float _2689;\n    if (_2687 > 0.0)\n    {\n        _2689 = _2687;\n    }\n    else\n    {\n        _2689 = 1.5 * _2637;\n    }\n    vec4 _2709 = vec4(world + (n * (_2689 * sqrt(1.0 - (_2642 * _2642)))), 1.0);\n    float _2713 = dot(_2615, _2709);\n    float _2716 = _2625.y;\n    if (_2713 < _2716)\n    {\n        return 1.0;\n    }\n    vec2 _2731 = vec2(dot(fa_light_texel(param_4), _2709), dot(fa_light_texel(param_5), _2709)) / vec2(_2713);\n    float _2733 = _2731.x;\n    bool _2736 = _2733 < _2620.x;\n    bool _2745;\n    if (!_2736)\n    {\n        _2745 = _2733 > _2620.z;\n    }\n    else\n    {\n        _2745 = _2736;\n    }\n    bool _2754;\n    if (!_2745)\n    {\n        _2754 = _2731.y < _2620.y;\n    }\n    else\n    {\n        _2754 = _2745;\n    }\n    bool _2763;\n    if (!_2754)\n    {\n        _2763 = _2731.y > _2620.w;\n    }\n    else\n    {\n        _2763 = _2754;\n    }\n    if (_2763)\n    {\n        return 1.0;\n    }\n    float _2769 = _2557.x;\n    float _2771;\n    if (_2769 > 0.0)\n    {\n        _2771 = _2769;\n    }\n    else\n    {\n        _2771 = 1.5 * _2637;\n    }\n    vec2 param_9 = _2731;\n    vec4 param_10 = _2620;\n    float param_11 = _2713 - (_2771 * (1.0 + (0.5 * _2684)));\n    float param_12 = _2637;\n    float param_13 = 1.0;\n    float param_14 = _2625.z * 0.25;\n    float param_15 = (_2637 * min(_2684, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2716, _2625.z);\n    int param_17 = int(_2552.z + 0.5);\n    float param_18 = _2552.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2056;\n    if (i == 0)\n    {\n        _2056 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2072;\n        if (i == 1)\n        {\n            _2072 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2080;\n            if (i == 2)\n            {\n                _2080 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2080 = fa_shadows[24].w;\n            }\n            _2072 = _2080;\n        }\n        _2056 = _2072;\n    }\n    return _2056;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2359 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2364 = clamp(dot(n, l), 0.0, 1.0);\n    float _2370 = sqrt(1.0 - (_2364 * _2364));\n    float _2378 = min(_2370 / max(_2364, 0.20000000298023223876953125), 4.0);\n    float _2383;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2383 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2383 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2408 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2383 * _2370)), 1.0);\n    float _2415 = _2408.x;\n    bool _2418 = _2415 < fa_shadows[ci * 1 + 16].x;\n    bool _2427;\n    if (!_2418)\n    {\n        _2427 = _2415 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2427 = _2418;\n    }\n    bool _2436;\n    if (!_2427)\n    {\n        _2436 = _2408.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2436 = _2427;\n    }\n    bool _2445;\n    if (!_2436)\n    {\n        _2445 = _2408.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2445 = _2436;\n    }\n    bool _2452;\n    if (!_2445)\n    {\n        _2452 = _2408.z > 1.0;\n    }\n    else\n    {\n        _2452 = _2445;\n    }\n    if (_2452)\n    {\n        return -1.0;\n    }\n    float _2460;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2460 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2460 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2408.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2408.z - ((_2460 * (1.0 + (0.5 * _2378))) / _2359);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2359;\n    float param_5 = _2359 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2378, 3.0)) * 0.5) / _2359;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2838 = int(fa_shadows[25].x + 0.5);\n    if (_2838 < 1)\n    {\n        return 1.0;\n    }\n    float _2853 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2838 - 1;\n    if (_2853 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2865 = _2838 > 1;\n    bool _2872;\n    if (_2865)\n    {\n        _2872 = _2853 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2872 = _2865;\n    }\n    if (_2872)\n    {\n        ci = 1;\n    }\n    bool _2876 = _2838 > 2;\n    bool _2883;\n    if (_2876)\n    {\n        _2883 = _2853 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2883 = _2876;\n    }\n    if (_2883)\n    {\n        ci = 2;\n    }\n    bool _2887 = _2838 > 3;\n    bool _2894;\n    if (_2887)\n    {\n        _2894 = _2853 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2894 = _2887;\n    }\n    if (_2894)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2838)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2920 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2920;\n        if (_2920 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2945;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2945 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2945 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2964 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2945, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2975 = clamp((_2853 - (fa_shadow_split_at(param_7) - _2964)) / _2964, 0.0, 1.0);\n        if (_2975 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2838)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2996 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2996;\n                if (_2996 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2975);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3447 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3454;\n    if (!_3447)\n    {\n        _3454 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3454 = _3447;\n    }\n    if (_3454)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3467 = fa_light_texel(param);\n    float _3468 = _3467.y;\n    float len = _3468;\n    if (_3468 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3480 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3490 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3480);\n    if (_3490 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3496 = len;\n    float _3499 = min(_3496, 0.89999997615814208984375 * dist);\n    len = _3499;\n    float _3505 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3480);\n    float _3510 = _3505 + (0.5 * _3499);\n    vec3 _3516 = world + (gn * _3505);\n    float _3518 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3583;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3534 = (float(k) + _3518) * 0.083333335816860198974609375;\n        vec3 _3542 = _3516 + (l * (_3534 * len));\n        vec4 _3548 = vec4(_3542, 1.0);\n        float _3554 = dot(fa_mesh_fs_params[28], _3548);\n        if (_3554 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3574 = vec2(dot(fa_mesh_fs_params[26], _3548), dot(fa_mesh_fs_params[27], _3548)) / vec2(_3554);\n        float _3578 = _3574.x * 0.5;\n        float _3579 = _3578 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3583 = (_3574.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3583 = 0.5 - (_3574.y * 0.5);\n        }\n        bool _3599 = _3579 < 0.0;\n        bool _3606;\n        if (!_3599)\n        {\n            _3606 = _3579 >= 1.0;\n        }\n        else\n        {\n            _3606 = _3599;\n        }\n        bool _3613;\n        if (!_3606)\n        {\n            _3613 = _3583 < 0.0;\n        }\n        else\n        {\n            _3613 = _3606;\n        }\n        bool _3620;\n        if (!_3613)\n        {\n            _3620 = _3583 >= 1.0;\n        }\n        else\n        {\n            _3620 = _3613;\n        }\n        if (_3620)\n        {\n            break;\n        }\n        vec4 _3647 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3579, _3583) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_3647.w < 0.5)\n        {\n            continue;\n        }\n        float _3666 = (dot(fa_mesh_fs_params[29].xyz, _3542) + fa_mesh_fs_params[29].w) - _3647.x;\n        if ((_3666 > _3505) && (_3666 < _3510))\n        {\n            occ = max(occ, (1.0 - (_3534 * _3534)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3579, 0.5 - _3578), min(_3583, 1.0 - _3583))));\n        }\n    }\n    return 1.0 - (occ * _3490);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _3769 = fa_baked_keep(param);\n    if (_3769 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3795 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _5576 = _3795.color;\n    float _5577 = _3795.attenuation;\n    float _5578 = _3795.shadow;\n    bool _3798 = _3795.type == 0;\n    if (_3798 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3795.direction;\n        float _3809 = fa_shadow_factor(param_5, param_6);\n        _5578 = _3809;\n        _5576 *= _3809;\n    }\n    else\n    {\n        bool _3820 = _3795.type != 0;\n        bool _3826;\n        if (_3820)\n        {\n            _3826 = _5577 > 0.0;\n        }\n        else\n        {\n            _3826 = _3820;\n        }\n        if (_3826)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3795.direction;\n            float _3845 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5578 = _3845;\n            _5576 *= _3845;\n        }\n    }\n    bool _3855 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3861;\n    if (_3855)\n    {\n        _3861 = _5577 > 0.0;\n    }\n    else\n    {\n        _3861 = _3855;\n    }\n    if (_3861)\n    {\n        float _3868;\n        if (_3798)\n        {\n            _3868 = 1000000000.0;\n        }\n        else\n        {\n            _3868 = _3795._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _3795.direction;\n        float param_18 = _3868;\n        float _3886 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5578 *= _3886;\n        _5576 *= _3886;\n    }\n    float _3899 = _5577;\n    float _3900 = _3899 * _3769;\n    _5577 = _3900;\n    vec3 _3904 = _5576;\n    vec3 _3905 = _3904 * _3769;\n    _5576 = _3905;\n    return LightSample(_3795.direction, _3905, _3900, _5578, _3795._distance, _3795.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3020 = int(fa_shadows[25].x + 0.5);\n    float _3030 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3035 = _3020 > 0;\n    bool _3044;\n    if (_3035)\n    {\n        int param = _3020 - 1;\n        _3044 = _3030 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3044 = _3035;\n    }\n    if (_3044)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3050 = _3020 > 1;\n        bool _3057;\n        if (_3050)\n        {\n            _3057 = _3030 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3057 = _3050;\n        }\n        if (_3057)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3063 = _3020 > 2;\n        bool _3070;\n        if (_3063)\n        {\n            _3070 = _3030 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3070 = _3063;\n        }\n        if (_3070)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3076 = _3020 > 3;\n        bool _3083;\n        if (_3076)\n        {\n            _3083 = _3030 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3083 = _3076;\n        }\n        if (_3083)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5397 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5397 = -_5397;\n    }\n    vec3 _4971 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5397, fa_world_tangent, fa_uv, fa_vertex_color, _4971, gl_FrontFacing);\n    Surface _4979 = fa_standard_surface(param_1);\n    vec3 _5428 = _4979.albedo;\n    float _5429 = _4979.alpha;\n    vec3 _5430 = _4979.normal;\n    float _5431 = _4979.metallic;\n    float _5432 = _4979.roughness;\n    float _5433 = _4979.occlusion;\n    vec3 _5434 = _4979.emission;\n    float _5435 = _4979.clearcoat;\n    float _5436 = _4979.clearcoat_roughness;\n    vec3 _5437 = _4979.sheen_color;\n    float _5438 = _4979.sheen_roughness;\n    float _5439 = _4979.anisotropy;\n    float _5440 = _4979.anisotropy_rotation;\n    float _5441 = _4979.specular;\n    float _5442 = _4979.ior;\n    vec3 _5443 = _4979.specular_color;\n    float _5444 = _4979.transmission;\n    float _5445 = _4979.thickness;\n    vec3 _5446 = _4979.attenuation_color;\n    float _5447 = _4979.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5397, fa_world_tangent, fa_uv, fa_vertex_color, _4971, gl_FrontFacing);\n    Surface param_3 = _4979;\n    surface(param_2, param_3);\n    _5428 = param_3.albedo;\n    _5429 = param_3.alpha;\n    _5430 = param_3.normal;\n    _5431 = param_3.metallic;\n    _5432 = param_3.roughness;\n    _5433 = param_3.occlusion;\n    _5434 = param_3.emission;\n    _5435 = param_3.clearcoat;\n    _5436 = param_3.clearcoat_roughness;\n    _5437 = param_3.sheen_color;\n    _5438 = param_3.sheen_roughness;\n    _5439 = param_3.anisotropy;\n    _5440 = param_3.anisotropy_rotation;\n    _5441 = param_3.specular;\n    _5442 = param_3.ior;\n    _5443 = param_3.specular_color;\n    _5444 = param_3.transmission;\n    _5445 = param_3.thickness;\n    _5446 = param_3.attenuation_color;\n    _5447 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5397;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5428 = param_6;\n    _5430 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5428;\n    }\n    else\n    {\n        vec3 _5018 = _5430;\n        vec3 _5019 = normalize(_5018);\n        _5430 = _5019;\n        vec3 param_8 = _5019;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _5428) * _5433;\n        int _5038 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5038; ln++)\n        {\n            int param_9 = ln;\n            int _5051 = fa_cl_light(param_9);\n            int param_10 = _5051;\n            if (fa_baked_keep(param_10) <= 0.0)\n            {\n                continue;\n            }\n            int param_11 = _5051;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _5397;\n            LightSample _5067 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _5397, fa_world_tangent, fa_uv, fa_vertex_color, _4971, gl_FrontFacing);\n            Surface param_15 = Surface(_5428, _5429, _5430, _5431, _5432, _5433, _5434, _5435, _5436, _5437, _5438, _5439, _5440, _5441, _5442, _5443, _5444, _5445, _5446, _5447);\n            LightSample param_16 = _5067;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _5082 = result;\n    vec3 _5083 = _5082 + _5434;\n    result = _5083;\n    vec3 param_17 = _5083;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _5092 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5099;\n    if (!_5092)\n    {\n        _5099 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5099 = _5092;\n    }\n    if (_5099)\n    {\n        vec3 _5108 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5114 = dot(_5108, fa_mesh_fs_params[9].xyz);\n        bool _5118 = fa_mesh_fs_params[9].w > 0.5;\n        float _5119;\n        if (_5118)\n        {\n            _5119 = _5114;\n        }\n        else\n        {\n            _5119 = length(_5108);\n        }\n        float _5131 = _5119 - fa_mesh_fs_params[8].x;\n        if (_5131 > 0.0)\n        {\n            float _5140 = fa_mesh_fs_params[7].w * _5131;\n            float tau = _5140 * _5140;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5156;\n                if (_5118)\n                {\n                    _5156 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5114);\n                }\n                else\n                {\n                    _5156 = fa_mesh_fs_params[0].y;\n                }\n                float _5177 = mix(_5156, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5119, 0.0, 1.0));\n                float _5181 = fa_world_pos.y - _5177;\n                float _5186 = _5177 - fa_mesh_fs_params[8].z;\n                float _5191 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5194 = _5186 <= 0.0;\n                bool _5195 = !_5194;\n                bool _5201;\n                if (_5195)\n                {\n                    _5201 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5201 = _5194;\n                }\n                float _5202;\n                if (_5201)\n                {\n                    _5202 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5202 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5186, 80.0));\n                }\n                bool _5229;\n                if (_5195)\n                {\n                    _5229 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5229 = _5194;\n                }\n                float _5230;\n                if (_5229)\n                {\n                    _5230 = fa_mesh_fs_params[8].y * _5186;\n                }\n                else\n                {\n                    _5230 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5186, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5255 = _5191 <= 0.0;\n                bool _5262;\n                if (!_5255)\n                {\n                    _5262 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5262 = _5255;\n                }\n                float _5263;\n                if (_5262)\n                {\n                    _5263 = fa_mesh_fs_params[8].y * _5191;\n                }\n                else\n                {\n                    _5263 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5191, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5290;\n                if (abs(_5181) < 0.001000000047497451305389404296875)\n                {\n                    _5290 = _5202;\n                }\n                else\n                {\n                    _5290 = (_5263 - _5230) / _5181;\n                }\n                tau += (_5131 * max(_5290, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5429);\n}\n\n",
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
            "inst_name": "_414",
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
            "inst_name": "_2066",
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
