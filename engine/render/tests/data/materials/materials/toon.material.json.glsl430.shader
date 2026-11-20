{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "57cbd5df71b0000e548dcd5fbfe873bc15510a64a336f6248792368f21adbf33",
  "slang": "glsl430",
  "params": [
    "dark"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_270, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[50];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1323 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1330;\n    if (!_1323)\n    {\n        _1330 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1330 = _1323;\n    }\n    bool _1338;\n    if (!_1330)\n    {\n        _1338 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1338 = _1330;\n    }\n    bool _1345;\n    if (!_1338)\n    {\n        _1345 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1345 = _1338;\n    }\n    bool _1352;\n    if (!_1345)\n    {\n        _1352 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1352 = _1345;\n    }\n    if (_1352)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1362 = vec4(world_pos, 1.0);\n    float _1368 = dot(fa_mesh_fs_params[16], _1362);\n    if (!(_1368 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1390 = vec2(dot(fa_mesh_fs_params[14], _1362), dot(fa_mesh_fs_params[15], _1362)) / vec2(_1368);\n    int _1394 = int(fa_mesh_fs_params[18].x);\n    int _1398 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1398) + clamp(int(floor(((_1390.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1398 - 1)) * _1394)) + clamp(int(floor(((_1390.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1394 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1474 = fa_cluster_texel(param);\n    return ivec2(int(_1474.x), int(_1474.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3650 = fa_cluster_lookup(param);\n    fa_cl_slot = _3650.x;\n    fa_cl_local = _3650.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3881 = fa_linear_to_srgb(param);\n        c = _3881;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3889 = fa_srgb_to_linear(param_1);\n            c = _3889;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _277;\n    if (i.front_facing)\n    {\n        _277 = i.world_normal;\n    }\n    else\n    {\n        _277 = -i.world_normal;\n    }\n    vec3 _301 = normalize(i.world_tangent.xyz - (_277 * dot(_277, i.world_tangent.xyz)));\n    vec3 _328 = normalize(((_301 * m.x) + ((cross(_277, _301) * i.world_tangent.w) * m.y)) + (_277 * m.z));\n    vec3 _331;\n    if (i.front_facing)\n    {\n        _331 = _328;\n    }\n    else\n    {\n        _331 = -_328;\n    }\n    return _331;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3920 = fa_tex_fix(param_2, param_3);\n    vec4 _4986 = base_t;\n    _4986.x = _3920.x;\n    _4986.y = _3920.y;\n    _4986.z = _3920.z;\n    base_t = _4986;\n    vec4 _3934 = (_4986 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4838 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3966 = fa_tex_fix(param_6, param_7);\n        vec3 _3969 = (_3966 * 2.0) - vec3(1.0);\n        vec2 _3974 = _3969.xy * fa_mesh_fs_params[6].x;\n        vec3 _4994 = _3969;\n        _4994.x = _3974.x;\n        _4994.y = _3974.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4994;\n        _4838 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4002 = fa_tex_fix(param_12, param_13);\n    vec4 _4997 = mrt;\n    _4997.x = _4002.x;\n    _4997.y = _4002.y;\n    _4997.z = _4002.z;\n    mrt = _4997;\n    vec4 _4030 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4030.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4041 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4071 = fa_tex_fix(param_20, param_21);\n    float _4843 = fa_mesh_fs_params[20].x;\n    float _4844 = fa_mesh_fs_params[20].y;\n    float _4847 = fa_mesh_fs_params[20].z;\n    float _4846 = fa_mesh_fs_params[21].w;\n    float _4849 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4843 *= _4041.y;\n            _4844 *= _4041.z;\n            _4846 *= _4030.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4847 *= mrt.x;\n            _4849 *= mrt.w;\n        }\n    }\n    return Surface(_3934.xyz, _3934.w, _4838, clamp(fa_mesh_fs_params[5].x * _4002.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4002.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4041.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4071), _4843, _4844, fa_mesh_fs_params[21].xyz, _4846, _4847, fa_mesh_fs_params[20].w, _4849, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1554 = rect.zw - rect.xy;\n    vec2 _1558 = _1554 * atlas;\n    vec2 _1562 = ddx * _1558;\n    vec2 _1566 = ddy * _1558;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1554), clamp(0.5 * log2(max(max(dot(_1562, _1562), dot(_1566, _1566)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1599 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1606;\n    if (!_1599)\n    {\n        _1606 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1606 = _1599;\n    }\n    if (_1606)\n    {\n        return;\n    }\n    vec3 _1612 = dFdx(world_pos);\n    vec3 _1615 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1619 = fa_cluster_texel(param);\n    int _1623 = int(_1619.w);\n    if (_1623 < 1)\n    {\n        return;\n    }\n    int _1633 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1633;\n    vec4 _1637 = fa_light_texel(param_1);\n    vec2 _1640 = _1637.yz;\n    int _1644 = int(_1637.w);\n    int param_2 = _1633 + 1;\n    vec4 _1649 = fa_light_texel(param_2);\n    float _1650 = _1649.x;\n    int _1656 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1660 = int(_1619.z);\n    vec3 _1925;\n    for (int k = 0; k < _1623; k++)\n    {\n        int _1673 = _1660 + k;\n        int param_3 = _1644 + (_1673 >> 2);\n        int _1690 = (_1633 + 2) + (int(fa_light_texel(param_3)[_1673 & 3]) * 7);\n        int param_4 = _1690 + 6;\n        vec4 _1695 = fa_light_texel(param_4);\n        if (((int(_1695.w + 0.5) >> _1656) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1690;\n        vec4 _1710 = fa_light_texel(param_5);\n        int param_6 = _1690 + 1;\n        vec4 _1715 = fa_light_texel(param_6);\n        int param_7 = _1690 + 2;\n        vec4 _1720 = fa_light_texel(param_7);\n        vec3 _1723 = _1710.xyz;\n        float _1728 = dot(_1723, world_pos) + _1710.w;\n        vec3 _1730 = _1715.xyz;\n        float _1735 = dot(_1730, world_pos) + _1715.w;\n        vec3 _1737 = _1720.xyz;\n        float _1742 = dot(_1737, world_pos) + _1720.w;\n        bool _1747 = abs(_1728) > 0.5;\n        bool _1755;\n        if (!_1747)\n        {\n            _1755 = abs(_1735) > 0.5;\n        }\n        else\n        {\n            _1755 = _1747;\n        }\n        bool _1763;\n        if (!_1755)\n        {\n            _1763 = abs(_1742) > 0.5;\n        }\n        else\n        {\n            _1763 = _1755;\n        }\n        if (_1763)\n        {\n            continue;\n        }\n        float _1778 = clamp(dot(geo_normal, normalize(_1737)) * _1695.z, 0.0, 1.0);\n        if (_1778 <= 0.0)\n        {\n            continue;\n        }\n        float _1798 = (clamp((0.5 - abs(_1742)) * 10.0, 0.0, 1.0) * _1778) * _1695.x;\n        vec2 _1806 = vec2(_1728 + 0.5, 0.5 - _1735);\n        vec2 _1816 = vec2(dot(_1723, _1612), dot(_1730, _1612));\n        vec2 _1826 = vec2(dot(_1723, _1615), dot(_1730, _1615));\n        int param_8 = _1690 + 5;\n        vec4 _1831 = fa_light_texel(param_8);\n        int param_9 = _1690 + 3;\n        vec4 _1836 = fa_light_texel(param_9);\n        int param_10 = _1690 + 4;\n        vec4 _1841 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1831.xyz;\n        bool _1851 = _1836.z > _1836.x;\n        if (_1851)\n        {\n            vec4 param_11 = _1836;\n            vec2 param_12 = _1806;\n            vec2 param_13 = _1640;\n            vec2 param_14 = _1816;\n            vec2 param_15 = _1826;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1650 > 0.5) && (_1650 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1877 = fa_dc_to_linear(param_16);\n                vec4 _4918 = tx;\n                _4918.x = _1877.x;\n                _4918.y = _1877.y;\n                _4918.z = _1877.z;\n                tx = _4918;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1798 * tex_a) * _1831.w, 0.0, 1.0)));\n        if (_1841.z > _1841.x)\n        {\n            vec4 param_17 = _1841;\n            vec2 param_18 = _1806;\n            vec2 param_19 = _1640;\n            vec2 param_20 = _1816;\n            vec2 param_21 = _1826;\n            vec4 _1921 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1650 > 1.5)\n            {\n                vec3 param_22 = _1921.xyz;\n                vec3 _1931 = fa_dc_to_srgb(param_22);\n                _1925 = _1931;\n            }\n            else\n            {\n                _1925 = _1921.xyz;\n            }\n            vec3 _1940 = (_1925 * 2.0) - vec3(1.0);\n            vec2 _1945 = _1940.xy * _1695.y;\n            vec3 _1967 = (normalize(_1723) * _1945.x) + (normalize(_1730) * _1945.y);\n            vec3 _1970 = normalize(normal);\n            normal = normalize(mix(_1970, normalize((_1970 * max(_1940.z, 0.0500000007450580596923828125)) + (_1967 - (_1970 * dot(_1970, _1967)))), vec3(clamp(_1798 * (_1851 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[39].y > 0.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3165 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3165;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3221 = (1.0 - fa_mesh_fs_params[40].w) - fa_mesh_fs_params[45].w;\n    vec3 amb = vec3(0.0);\n    bool _3227 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3221 > 0.0005000000237487256526947021484375)\n    {\n        if (_3227)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[39].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3221;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3221;\n        }\n    }\n    bool _3280 = fa_mesh_fs_params[40].w > 0.0;\n    if (_3280)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[40].xy;\n            float param_4 = fa_mesh_fs_params[40].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[40].w);\n        }\n    }\n    bool _3311 = fa_mesh_fs_params[45].w > 0.0;\n    if (_3311)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[45].xy;\n            float param_7 = fa_mesh_fs_params[45].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[45].w);\n        }\n    }\n    if ((_3227 || _3280) || _3311)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[30].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 30].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[30].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3620;\n    if (fa_lm.z > 0.5)\n    {\n        _3620 = 0.0;\n    }\n    else\n    {\n        _3620 = 1.0 - clamp(fa_mesh_fs_params[30].w, 0.0, 1.0);\n    }\n    bool _3631 = _3620 < 1.0;\n    bool _3637;\n    if (_3631)\n    {\n        int param = li;\n        _3637 = fa_light_baked(param);\n    }\n    else\n    {\n        _3637 = _3631;\n    }\n    return _3637 ? _3620 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _573 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _586 = (c - (ru * hx)) - p;\n        vec3 _592 = ru * (2.0 * hx);\n        float _598 = max(dot(_592, _592), 9.9999999392252902907785028219223e-09);\n        float _602 = dot(_586, _592);\n        float t = clamp((-_602) / _598, 0.0, 1.0);\n        if (_573)\n        {\n            float _617 = dot(r, _592);\n            float _623 = _598 - (_617 * _617);\n            if (abs(_623) > (9.9999997473787516355514526367188e-06 * _598))\n            {\n                t = clamp(((dot(r, _586) * _617) - _602) / _623, 0.0, 1.0);\n            }\n        }\n        return (p + _586) + (_592 * t);\n    }\n    vec3 q = p;\n    float _655 = dot(r, axis);\n    bool _663;\n    if (_573)\n    {\n        _663 = abs(_655) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _663 = _573;\n    }\n    if (_663)\n    {\n        float _673 = dot(c - p, axis) / _655;\n        if (_673 > 0.0)\n        {\n            q = p + (r * _673);\n        }\n    }\n    vec3 _686 = q - c;\n    vec2 xy = vec2(dot(_686, ru), dot(_686, uu));\n    if (shape > 0.5)\n    {\n        float _701 = length(xy);\n        if (_701 > hx)\n        {\n            xy *= (hx / _701);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _343 = abs(d);\n    float _345 = _343.x;\n    float _347 = _343.y;\n    bool _348 = _345 >= _347;\n    bool _356;\n    if (_348)\n    {\n        _356 = _345 >= _343.z;\n    }\n    else\n    {\n        _356 = _348;\n    }\n    int _357;\n    if (_356)\n    {\n        _357 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _372;\n        if (_347 >= _343.z)\n        {\n            _372 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _372 = (d.z > 0.0) ? 4 : 5;\n        }\n        _357 = _372;\n    }\n    return _357;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _493 = dot(d, right);\n    float _497 = dot(d, up);\n    float _508;\n    if (((_493 * _493) + (_497 * _497)) > 1.0000000133514319600180897396058e-10)\n    {\n        _508 = atan(_497, _493) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _508 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_508 - floor(_508)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _739 = fa_light_base(param);\n    bool _743 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _739;\n    vec4 _747 = fa_light_texel(param_1);\n    int param_2 = _739 + 1;\n    vec4 _752 = fa_light_texel(param_2);\n    float _755 = _752.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _767 = _743 && (_755 > 2.5);\n    fa_light_is_area = _767;\n    bool _769 = _755 < 0.5;\n    vec3 l;\n    if (_769)\n    {\n        l = normalize(_747.xyz);\n        if (_743)\n        {\n            int param_3 = _739 + 6;\n            vec4 _783 = fa_light_texel(param_3);\n            if (_783.z > 0.5)\n            {\n                int param_4 = _739 + 4;\n                vec4 _793 = fa_light_texel(param_4);\n                int param_5 = _739 + 5;\n                vec4 _798 = fa_light_texel(param_5);\n                vec2 param_6 = _783.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _793.xyz) * _793.w, (-dot(world_pos, _798.xyz)) * _798.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _828 = _747.xyz;\n        vec3 _830 = _828 - world_pos;\n        vec3 to_light = _830;\n        float _833 = length(_830);\n        float reach = _833;\n        bool front = true;\n        if (_767)\n        {\n            int param_8 = _739 + 7;\n            reach = max(_833 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _739 + 4;\n            vec4 _857 = fa_light_texel(param_9);\n            int param_10 = _739 + 5;\n            vec4 _862 = fa_light_texel(param_10);\n            int param_11 = _739 + 6;\n            vec4 _867 = fa_light_texel(param_11);\n            float _868 = _867.w;\n            int param_12 = _739 + 2;\n            vec3 _875 = normalize(fa_light_texel(param_12).xyz);\n            bool _877 = _868 > 1.5;\n            bool _885;\n            if (!_877)\n            {\n                _885 = dot(_875, to_light) < 0.0;\n            }\n            else\n            {\n                _885 = _877;\n            }\n            front = _885;\n            vec3 r = vec3(0.0);\n            vec3 _894 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _898 = dot(n, n) > 0.5;\n            bool _906;\n            if (_898)\n            {\n                _906 = dot(_894, _894) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _906 = _898;\n            }\n            if (_906)\n            {\n                r = reflect(-normalize(_894), normalize(n));\n            }\n            vec3 param_13 = _828;\n            vec3 param_14 = _875;\n            vec3 param_15 = _857.xyz;\n            vec3 param_16 = _862.xyz;\n            float param_17 = _857.w;\n            float param_18 = _862.w;\n            float param_19 = _868;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _942 = length(to_light);\n        dist = _942;\n        l = to_light / vec3(max(_942, 9.9999997473787516355514526367188e-05));\n        float _956 = reach / max(_747.w, 0.001000000047497451305389404296875);\n        float _962 = clamp(1.0 - (_956 * _956), 0.0, 1.0);\n        float _964;\n        if (front)\n        {\n            _964 = _962 * _962;\n        }\n        else\n        {\n            _964 = 0.0;\n        }\n        atten = _964;\n        bool _975 = _755 < 2.5;\n        if ((_755 > 1.5) && _975)\n        {\n            int param_22 = _739 + 2;\n            vec4 _983 = fa_light_texel(param_22);\n            float _993 = _983.w;\n            int param_23 = _739 + 3;\n            vec4 _998 = fa_light_texel(param_23);\n            float _999 = _998.x;\n            float cos_inner = _999;\n            if (_999 > 1.5)\n            {\n                cos_inner = mix(_993, 1.0, 0.25);\n            }\n            atten *= smoothstep(_993, cos_inner, dot(-l, normalize(_983.xyz)));\n        }\n        if (_743 && (_755 < 1.5))\n        {\n            int param_24 = _739 + 6;\n            vec4 _1023 = fa_light_texel(param_24);\n            if (_1023.z > 0.5)\n            {\n                vec3 _1031 = -to_light;\n                int param_25 = _739 + 4;\n                int param_26 = _739 + 5;\n                vec3 _1045 = fa_light_texel(param_25).xyz;\n                vec3 _1049 = fa_light_texel(param_26).xyz;\n                vec3 _1058 = vec3(dot(_1031, _1045), dot(_1031, _1049), dot(_1031, cross(_1045, _1049)));\n                vec3 param_27 = _1058;\n                int _1062 = fa_cube_face(param_27);\n                int param_28 = _1062;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1089 = vec2(dot(_1058, cross(param_29, param_30)), dot(_1058, param_30)) / vec2(max(dot(_1058, param_29), 9.9999997473787516355514526367188e-05));\n                int _1093 = _1062 / 3;\n                vec2 param_31 = _1023.xy + (vec2(float(_1062 - (_1093 * 3)), float(_1093)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1089.x), 0.5 - (0.5 * _1089.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _739 + 7;\n            vec4 _1123 = fa_light_texel(param_33);\n            if (_1123.z > 0.5)\n            {\n                int param_34 = _739 + 2;\n                int param_35 = _739 + 4;\n                int param_36 = _739 + 5;\n                vec2 param_37 = _1123.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_743 && _975)\n            {\n                int param_42 = _739 + 6;\n                vec4 _1170 = fa_light_texel(param_42);\n                int param_43 = _739 + 7;\n                vec4 _1175 = fa_light_texel(param_43);\n                bool _1178 = _1170.z > 0.5;\n                bool _1185;\n                if (!_1178)\n                {\n                    _1185 = _1175.z > 0.5;\n                }\n                else\n                {\n                    _1185 = _1178;\n                }\n                if (_1185)\n                {\n                    int param_44 = _739 + 2;\n                    vec4 _1192 = fa_light_texel(param_44);\n                    vec3 _1196 = normalize(_1192.xyz);\n                    int param_45 = _739 + 4;\n                    vec4 _1201 = fa_light_texel(param_45);\n                    int param_46 = _739 + 5;\n                    vec4 _1206 = fa_light_texel(param_46);\n                    if (_1178)\n                    {\n                        vec3 _1214 = -to_light;\n                        float _1221 = _1192.w;\n                        float _1237 = 0.5 / max(dot(_1214, _1196) * (sqrt(max(1.0 - (_1221 * _1221), 0.0)) / max(_1221, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1170.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1214, _1201.xyz) * _1237), 0.5 - (dot(_1214, _1206.xyz) * _1237));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1175.z > 0.5)\n                    {\n                        vec2 param_49 = _1175.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1196;\n                        vec3 param_52 = _1201.xyz;\n                        vec3 param_53 = _1206.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _4792 = _752.xyz * atten;\n    if (_743)\n    {\n        _4792 *= fa_light_tint;\n    }\n    int _1305;\n    if (_769)\n    {\n        _1305 = 0;\n    }\n    else\n    {\n        _1305 = ((_755 > 1.5) && (_755 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4792, atten, 1.0, dist, _1305);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2042;\n    if (i == 0)\n    {\n        _2042 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2058;\n        if (i == 1)\n        {\n            _2058 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2066;\n            if (i == 2)\n            {\n                _2066 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2066 = fa_shadows[24].w;\n            }\n            _2058 = _2066;\n        }\n        _2042 = _2058;\n    }\n    return _2042;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2099 = fa_shadow_depth(param, param_1);\n    float _2103;\n    if (conv.x < 0.5)\n    {\n        _2103 = _2099;\n    }\n    else\n    {\n        _2103 = (conv.y * conv.z) / (conv.z - (_2099 * (conv.z - conv.y)));\n    }\n    return _2103;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2030 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2030), sin(_2030)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2149 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2158;\n        if (k < 0.0)\n        {\n            _2158 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2158 = k;\n        }\n        float _2178 = clamp((_2158 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2149;\n            vec2 _2197 = fa_shadow_vogel(param_3, param_4, param_5) * _2178;\n            vec2 param_6 = uv + (_2197 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2209 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2209 < (zr - (length(_2197) * plane)))\n            {\n                sum += _2209;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2235 = sum / cnt;\n        float _2245;\n        if (k < 0.0)\n        {\n            _2245 = (-k) / max(_2235, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2245 = k;\n        }\n        radius = clamp(((max(zr - _2235, 0.0) * unit) * _2245) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2267 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2267; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2267;\n        float param_11 = _2149;\n        vec2 _2286 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2286 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2286) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2267);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2328 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2333 = clamp(dot(n, l), 0.0, 1.0);\n    float _2339 = sqrt(1.0 - (_2333 * _2333));\n    float _2346 = min(_2339 / max(_2333, 0.20000000298023223876953125), 4.0);\n    float _2351;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2351 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2351 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2376 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2351 * _2339)), 1.0);\n    float _2383 = _2376.x;\n    bool _2386 = _2383 < fa_shadows[ci * 1 + 16].x;\n    bool _2395;\n    if (!_2386)\n    {\n        _2395 = _2383 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2395 = _2386;\n    }\n    bool _2404;\n    if (!_2395)\n    {\n        _2404 = _2376.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2404 = _2395;\n    }\n    bool _2413;\n    if (!_2404)\n    {\n        _2413 = _2376.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2413 = _2404;\n    }\n    bool _2420;\n    if (!_2413)\n    {\n        _2420 = _2376.z > 1.0;\n    }\n    else\n    {\n        _2420 = _2413;\n    }\n    if (_2420)\n    {\n        return -1.0;\n    }\n    float _2428;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2428 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2428 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2376.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2376.z - ((_2428 * (1.0 + (0.5 * _2346))) / _2328);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2328;\n    float param_5 = _2328 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2346, 3.0)) * 0.5) / _2328;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2806 = int(fa_shadows[25].x + 0.5);\n    if (_2806 < 1)\n    {\n        return 1.0;\n    }\n    float _2821 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2806 - 1;\n    if (_2821 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2833 = _2806 > 1;\n    bool _2840;\n    if (_2833)\n    {\n        _2840 = _2821 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2840 = _2833;\n    }\n    if (_2840)\n    {\n        ci = 1;\n    }\n    bool _2844 = _2806 > 2;\n    bool _2851;\n    if (_2844)\n    {\n        _2851 = _2821 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2851 = _2844;\n    }\n    if (_2851)\n    {\n        ci = 2;\n    }\n    bool _2855 = _2806 > 3;\n    bool _2862;\n    if (_2855)\n    {\n        _2862 = _2821 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2862 = _2855;\n    }\n    if (_2862)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2806)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2888 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2888;\n        if (_2888 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2913;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2913 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2913 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2932 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2913, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2943 = clamp((_2821 - (fa_shadow_split_at(param_7) - _2932)) / _2932, 0.0, 1.0);\n        if (_2943 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2806)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2964 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2964;\n                if (_2964 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2943);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2486 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2493;\n    if (!_2486)\n    {\n        _2493 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2493 = _2486;\n    }\n    if (_2493)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2506 = fa_light_texel(param);\n    float _2507 = _2506.x;\n    if (_2507 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2516 = int(_2507 + 0.5);\n    int param_1 = _2516;\n    vec4 _2520 = fa_light_texel(param_1);\n    int param_2 = _2516 + 1;\n    vec4 _2525 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2528 = _2520.y;\n    if (_2528 > 0.0)\n    {\n        float _2545 = 1.0 - smoothstep(0.75 * _2528, _2528, length(world - fa_shadows[27].xyz));\n        fade = _2545;\n        if (_2545 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2520.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2569 = (_2516 + 2) + (face * 6);\n    int param_4 = _2569;\n    int param_5 = _2569 + 1;\n    int param_6 = _2569 + 3;\n    vec4 _2583 = fa_light_texel(param_6);\n    int param_7 = _2569 + 4;\n    vec4 _2588 = fa_light_texel(param_7);\n    int param_8 = _2569 + 5;\n    vec4 _2593 = fa_light_texel(param_8);\n    float _2605 = _2593.x * max(dot(_2583, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2610 = clamp(dot(n, l), 0.0, 1.0);\n    float _2633 = clamp(dot(n, _2583.xyz), -1.0, 1.0);\n    float _2652 = min(sqrt(1.0 - (_2633 * _2633)) / max(abs(dot(n, world - lpos)) / max(dot(_2583, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2655 = _2525.y;\n    float _2657;\n    if (_2655 > 0.0)\n    {\n        _2657 = _2655;\n    }\n    else\n    {\n        _2657 = 1.5 * _2605;\n    }\n    vec4 _2677 = vec4(world + (n * (_2657 * sqrt(1.0 - (_2610 * _2610)))), 1.0);\n    float _2681 = dot(_2583, _2677);\n    float _2684 = _2593.y;\n    if (_2681 < _2684)\n    {\n        return 1.0;\n    }\n    vec2 _2699 = vec2(dot(fa_light_texel(param_4), _2677), dot(fa_light_texel(param_5), _2677)) / vec2(_2681);\n    float _2701 = _2699.x;\n    bool _2704 = _2701 < _2588.x;\n    bool _2713;\n    if (!_2704)\n    {\n        _2713 = _2701 > _2588.z;\n    }\n    else\n    {\n        _2713 = _2704;\n    }\n    bool _2722;\n    if (!_2713)\n    {\n        _2722 = _2699.y < _2588.y;\n    }\n    else\n    {\n        _2722 = _2713;\n    }\n    bool _2731;\n    if (!_2722)\n    {\n        _2731 = _2699.y > _2588.w;\n    }\n    else\n    {\n        _2731 = _2722;\n    }\n    if (_2731)\n    {\n        return 1.0;\n    }\n    float _2737 = _2525.x;\n    float _2739;\n    if (_2737 > 0.0)\n    {\n        _2739 = _2737;\n    }\n    else\n    {\n        _2739 = 1.5 * _2605;\n    }\n    vec2 param_9 = _2699;\n    vec4 param_10 = _2588;\n    float param_11 = _2681 - (_2739 * (1.0 + (0.5 * _2652)));\n    float param_12 = _2605;\n    float param_13 = 1.0;\n    float param_14 = _2593.z * 0.25;\n    float param_15 = (_2605 * min(_2652, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2684, _2593.z);\n    int param_17 = int(_2520.z + 0.5);\n    float param_18 = _2520.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3362 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3369;\n    if (!_3362)\n    {\n        _3369 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3369 = _3362;\n    }\n    if (_3369)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3382 = fa_light_texel(param);\n    float _3383 = _3382.y;\n    float len = _3383;\n    if (_3383 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3395 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3405 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3395);\n    if (_3405 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3411 = len;\n    float _3414 = min(_3411, 0.89999997615814208984375 * dist);\n    len = _3414;\n    float _3420 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3395);\n    float _3425 = _3420 + (0.5 * _3414);\n    vec3 _3431 = world + (gn * _3420);\n    float _3433 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3498;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3449 = (float(k) + _3433) * 0.083333335816860198974609375;\n        vec3 _3457 = _3431 + (l * (_3449 * len));\n        vec4 _3463 = vec4(_3457, 1.0);\n        float _3469 = dot(fa_mesh_fs_params[28], _3463);\n        if (_3469 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3489 = vec2(dot(fa_mesh_fs_params[26], _3463), dot(fa_mesh_fs_params[27], _3463)) / vec2(_3469);\n        float _3493 = _3489.x * 0.5;\n        float _3494 = _3493 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3498 = (_3489.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3498 = 0.5 - (_3489.y * 0.5);\n        }\n        bool _3514 = _3494 < 0.0;\n        bool _3521;\n        if (!_3514)\n        {\n            _3521 = _3494 >= 1.0;\n        }\n        else\n        {\n            _3521 = _3514;\n        }\n        bool _3528;\n        if (!_3521)\n        {\n            _3528 = _3498 < 0.0;\n        }\n        else\n        {\n            _3528 = _3521;\n        }\n        bool _3535;\n        if (!_3528)\n        {\n            _3535 = _3498 >= 1.0;\n        }\n        else\n        {\n            _3535 = _3528;\n        }\n        if (_3535)\n        {\n            break;\n        }\n        vec4 _3554 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_3494, _3498) * fa_mesh_fs_params[24].zw), 0);\n        if (_3554.w < 0.5)\n        {\n            continue;\n        }\n        float _3573 = (dot(fa_mesh_fs_params[29].xyz, _3457) + fa_mesh_fs_params[29].w) - _3554.x;\n        if ((_3573 > _3420) && (_3573 < _3425))\n        {\n            occ = max(occ, (1.0 - (_3449 * _3449)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3494, 0.5 - _3493), min(_3498, 1.0 - _3498))));\n        }\n    }\n    return 1.0 - (occ * _3405);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _3676 = fa_baked_keep(param);\n    if (_3676 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3702 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _4818 = _3702.color;\n    float _4819 = _3702.attenuation;\n    float _4820 = _3702.shadow;\n    bool _3705 = _3702.type == 0;\n    if (_3705 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3702.direction;\n        float _3716 = fa_shadow_factor(param_5, param_6);\n        _4820 = _3716;\n        _4818 *= _3716;\n    }\n    else\n    {\n        bool _3727 = _3702.type != 0;\n        bool _3733;\n        if (_3727)\n        {\n            _3733 = _4819 > 0.0;\n        }\n        else\n        {\n            _3733 = _3727;\n        }\n        if (_3733)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3702.direction;\n            float _3752 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4820 = _3752;\n            _4818 *= _3752;\n        }\n    }\n    bool _3762 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3768;\n    if (_3762)\n    {\n        _3768 = _4819 > 0.0;\n    }\n    else\n    {\n        _3768 = _3762;\n    }\n    if (_3768)\n    {\n        float _3775;\n        if (_3705)\n        {\n            _3775 = 1000000000.0;\n        }\n        else\n        {\n            _3775 = _3702._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _3702.direction;\n        float param_18 = _3775;\n        float _3793 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _4820 *= _3793;\n        _4818 *= _3793;\n    }\n    float _3806 = _4819;\n    float _3807 = _3806 * _3676;\n    _4819 = _3807;\n    vec3 _3811 = _4818;\n    vec3 _3812 = _3811 * _3676;\n    _4818 = _3812;\n    return LightSample(_3702.direction, _3812, _3807, _4820, _3702._distance, _3702.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _3826;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _3826 = 1.0;\n    }\n    else\n    {\n        _3826 = fa_material[0].x;\n    }\n    return (s.albedo * l.color) * _3826;\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2988 = int(fa_shadows[25].x + 0.5);\n    float _2998 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3003 = _2988 > 0;\n    bool _3012;\n    if (_3003)\n    {\n        int param = _2988 - 1;\n        _3012 = _2998 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3012 = _3003;\n    }\n    if (_3012)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3018 = _2988 > 1;\n        bool _3025;\n        if (_3018)\n        {\n            _3025 = _2998 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3025 = _3018;\n        }\n        if (_3025)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3031 = _2988 > 2;\n        bool _3038;\n        if (_3031)\n        {\n            _3038 = _2998 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3038 = _3031;\n        }\n        if (_3038)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3044 = _2988 > 3;\n        bool _3051;\n        if (_3044)\n        {\n            _3051 = _2998 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3051 = _3044;\n        }\n        if (_3051)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4659 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4659 = -_4659;\n    }\n    vec3 _4250 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4659, fa_world_tangent, fa_uv, fa_vertex_color, _4250, gl_FrontFacing);\n    Surface _4258 = fa_standard_surface(param_1);\n    vec3 _4690 = _4258.albedo;\n    float _4691 = _4258.alpha;\n    vec3 _4692 = _4258.normal;\n    float _4693 = _4258.metallic;\n    float _4694 = _4258.roughness;\n    float _4695 = _4258.occlusion;\n    vec3 _4696 = _4258.emission;\n    float _4697 = _4258.clearcoat;\n    float _4698 = _4258.clearcoat_roughness;\n    vec3 _4699 = _4258.sheen_color;\n    float _4700 = _4258.sheen_roughness;\n    float _4701 = _4258.anisotropy;\n    float _4702 = _4258.anisotropy_rotation;\n    float _4703 = _4258.specular;\n    float _4704 = _4258.ior;\n    vec3 _4705 = _4258.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4659, fa_world_tangent, fa_uv, fa_vertex_color, _4250, gl_FrontFacing);\n    Surface param_3 = _4258;\n    surface(param_2, param_3);\n    _4690 = param_3.albedo;\n    _4691 = param_3.alpha;\n    _4692 = param_3.normal;\n    _4693 = param_3.metallic;\n    _4694 = param_3.roughness;\n    _4695 = param_3.occlusion;\n    _4696 = param_3.emission;\n    _4697 = param_3.clearcoat;\n    _4698 = param_3.clearcoat_roughness;\n    _4699 = param_3.sheen_color;\n    _4700 = param_3.sheen_roughness;\n    _4701 = param_3.anisotropy;\n    _4702 = param_3.anisotropy_rotation;\n    _4703 = param_3.specular;\n    _4704 = param_3.ior;\n    _4705 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4659;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4690 = param_6;\n    _4692 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4690;\n    }\n    else\n    {\n        vec3 _4296 = _4692;\n        vec3 _4297 = normalize(_4296);\n        _4692 = _4297;\n        vec3 param_8 = _4297;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _4690) * _4695;\n        int _4316 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4316; ln++)\n        {\n            int param_9 = ln;\n            int _4329 = fa_cl_light(param_9);\n            int param_10 = _4329;\n            if (fa_baked_keep(param_10) <= 0.0)\n            {\n                continue;\n            }\n            int param_11 = _4329;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _4659;\n            LightSample _4345 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _4659, fa_world_tangent, fa_uv, fa_vertex_color, _4250, gl_FrontFacing);\n            Surface param_15 = Surface(_4690, _4691, _4692, _4693, _4694, _4695, _4696, _4697, _4698, _4699, _4700, _4701, _4702, _4703, _4704, _4705);\n            LightSample param_16 = _4345;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _4360 = result;\n    vec3 _4361 = _4360 + _4696;\n    result = _4361;\n    vec3 param_17 = _4361;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _4370 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4377;\n    if (!_4370)\n    {\n        _4377 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4377 = _4370;\n    }\n    if (_4377)\n    {\n        vec3 _4386 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4392 = dot(_4386, fa_mesh_fs_params[9].xyz);\n        bool _4396 = fa_mesh_fs_params[9].w > 0.5;\n        float _4397;\n        if (_4396)\n        {\n            _4397 = _4392;\n        }\n        else\n        {\n            _4397 = length(_4386);\n        }\n        float _4409 = _4397 - fa_mesh_fs_params[8].x;\n        if (_4409 > 0.0)\n        {\n            float _4418 = fa_mesh_fs_params[7].w * _4409;\n            float tau = _4418 * _4418;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4434;\n                if (_4396)\n                {\n                    _4434 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4392);\n                }\n                else\n                {\n                    _4434 = fa_mesh_fs_params[0].y;\n                }\n                float _4455 = mix(_4434, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4397, 0.0, 1.0));\n                float _4459 = fa_world_pos.y - _4455;\n                float _4464 = _4455 - fa_mesh_fs_params[8].z;\n                float _4469 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4472 = _4464 <= 0.0;\n                bool _4473 = !_4472;\n                bool _4479;\n                if (_4473)\n                {\n                    _4479 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4479 = _4472;\n                }\n                float _4480;\n                if (_4479)\n                {\n                    _4480 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4480 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4464, 80.0));\n                }\n                bool _4507;\n                if (_4473)\n                {\n                    _4507 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4507 = _4472;\n                }\n                float _4508;\n                if (_4507)\n                {\n                    _4508 = fa_mesh_fs_params[8].y * _4464;\n                }\n                else\n                {\n                    _4508 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4464, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4533 = _4469 <= 0.0;\n                bool _4540;\n                if (!_4533)\n                {\n                    _4540 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4540 = _4533;\n                }\n                float _4541;\n                if (_4540)\n                {\n                    _4541 = fa_mesh_fs_params[8].y * _4469;\n                }\n                else\n                {\n                    _4541 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4469, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4568;\n                if (abs(_4459) < 0.001000000047497451305389404296875)\n                {\n                    _4568 = _4480;\n                }\n                else\n                {\n                    _4568 = (_4541 - _4508) / _4459;\n                }\n                tau += (_4409 * max(_4568, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4691);\n}\n\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_395",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 50,
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
            "inst_name": "_2052",
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
            "inst_name": "_3832",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_391, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[50];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1323 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1330;\n    if (!_1323)\n    {\n        _1330 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1330 = _1323;\n    }\n    bool _1338;\n    if (!_1330)\n    {\n        _1338 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1338 = _1330;\n    }\n    bool _1345;\n    if (!_1338)\n    {\n        _1345 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1345 = _1338;\n    }\n    bool _1352;\n    if (!_1345)\n    {\n        _1352 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1352 = _1345;\n    }\n    if (_1352)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1362 = vec4(world_pos, 1.0);\n    float _1368 = dot(fa_mesh_fs_params[16], _1362);\n    if (!(_1368 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1390 = vec2(dot(fa_mesh_fs_params[14], _1362), dot(fa_mesh_fs_params[15], _1362)) / vec2(_1368);\n    int _1394 = int(fa_mesh_fs_params[18].x);\n    int _1398 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1398) + clamp(int(floor(((_1390.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1398 - 1)) * _1394)) + clamp(int(floor(((_1390.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1394 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1474 = fa_cluster_texel(param);\n    return ivec2(int(_1474.x), int(_1474.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3650 = fa_cluster_lookup(param);\n    fa_cl_slot = _3650.x;\n    fa_cl_local = _3650.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3881 = fa_linear_to_srgb(param);\n        c = _3881;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3889 = fa_srgb_to_linear(param_1);\n            c = _3889;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _277;\n    if (i.front_facing)\n    {\n        _277 = i.world_normal;\n    }\n    else\n    {\n        _277 = -i.world_normal;\n    }\n    vec3 _301 = normalize(i.world_tangent.xyz - (_277 * dot(_277, i.world_tangent.xyz)));\n    vec3 _328 = normalize(((_301 * m.x) + ((cross(_277, _301) * i.world_tangent.w) * m.y)) + (_277 * m.z));\n    vec3 _331;\n    if (i.front_facing)\n    {\n        _331 = _328;\n    }\n    else\n    {\n        _331 = -_328;\n    }\n    return _331;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3920 = fa_tex_fix(param_2, param_3);\n    vec4 _4986 = base_t;\n    _4986.x = _3920.x;\n    _4986.y = _3920.y;\n    _4986.z = _3920.z;\n    base_t = _4986;\n    vec4 _3934 = (_4986 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4838 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3966 = fa_tex_fix(param_6, param_7);\n        vec3 _3969 = (_3966 * 2.0) - vec3(1.0);\n        vec2 _3974 = _3969.xy * fa_mesh_fs_params[6].x;\n        vec3 _4994 = _3969;\n        _4994.x = _3974.x;\n        _4994.y = _3974.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4994;\n        _4838 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4002 = fa_tex_fix(param_12, param_13);\n    vec4 _4997 = mrt;\n    _4997.x = _4002.x;\n    _4997.y = _4002.y;\n    _4997.z = _4002.z;\n    mrt = _4997;\n    vec4 _4030 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4030.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4041 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4071 = fa_tex_fix(param_20, param_21);\n    float _4843 = fa_mesh_fs_params[20].x;\n    float _4844 = fa_mesh_fs_params[20].y;\n    float _4847 = fa_mesh_fs_params[20].z;\n    float _4846 = fa_mesh_fs_params[21].w;\n    float _4849 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4843 *= _4041.y;\n            _4844 *= _4041.z;\n            _4846 *= _4030.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4847 *= mrt.x;\n            _4849 *= mrt.w;\n        }\n    }\n    return Surface(_3934.xyz, _3934.w, _4838, clamp(fa_mesh_fs_params[5].x * _4002.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4002.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4041.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4071), _4843, _4844, fa_mesh_fs_params[21].xyz, _4846, _4847, fa_mesh_fs_params[20].w, _4849, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1554 = rect.zw - rect.xy;\n    vec2 _1558 = _1554 * atlas;\n    vec2 _1562 = ddx * _1558;\n    vec2 _1566 = ddy * _1558;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1554), clamp(0.5 * log2(max(max(dot(_1562, _1562), dot(_1566, _1566)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1599 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1606;\n    if (!_1599)\n    {\n        _1606 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1606 = _1599;\n    }\n    if (_1606)\n    {\n        return;\n    }\n    vec3 _1612 = dFdx(world_pos);\n    vec3 _1615 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1619 = fa_cluster_texel(param);\n    int _1623 = int(_1619.w);\n    if (_1623 < 1)\n    {\n        return;\n    }\n    int _1633 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1633;\n    vec4 _1637 = fa_light_texel(param_1);\n    vec2 _1640 = _1637.yz;\n    int _1644 = int(_1637.w);\n    int param_2 = _1633 + 1;\n    vec4 _1649 = fa_light_texel(param_2);\n    float _1650 = _1649.x;\n    int _1656 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1660 = int(_1619.z);\n    vec3 _1925;\n    for (int k = 0; k < _1623; k++)\n    {\n        int _1673 = _1660 + k;\n        int param_3 = _1644 + (_1673 >> 2);\n        int _1690 = (_1633 + 2) + (int(fa_light_texel(param_3)[_1673 & 3]) * 7);\n        int param_4 = _1690 + 6;\n        vec4 _1695 = fa_light_texel(param_4);\n        if (((int(_1695.w + 0.5) >> _1656) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1690;\n        vec4 _1710 = fa_light_texel(param_5);\n        int param_6 = _1690 + 1;\n        vec4 _1715 = fa_light_texel(param_6);\n        int param_7 = _1690 + 2;\n        vec4 _1720 = fa_light_texel(param_7);\n        vec3 _1723 = _1710.xyz;\n        float _1728 = dot(_1723, world_pos) + _1710.w;\n        vec3 _1730 = _1715.xyz;\n        float _1735 = dot(_1730, world_pos) + _1715.w;\n        vec3 _1737 = _1720.xyz;\n        float _1742 = dot(_1737, world_pos) + _1720.w;\n        bool _1747 = abs(_1728) > 0.5;\n        bool _1755;\n        if (!_1747)\n        {\n            _1755 = abs(_1735) > 0.5;\n        }\n        else\n        {\n            _1755 = _1747;\n        }\n        bool _1763;\n        if (!_1755)\n        {\n            _1763 = abs(_1742) > 0.5;\n        }\n        else\n        {\n            _1763 = _1755;\n        }\n        if (_1763)\n        {\n            continue;\n        }\n        float _1778 = clamp(dot(geo_normal, normalize(_1737)) * _1695.z, 0.0, 1.0);\n        if (_1778 <= 0.0)\n        {\n            continue;\n        }\n        float _1798 = (clamp((0.5 - abs(_1742)) * 10.0, 0.0, 1.0) * _1778) * _1695.x;\n        vec2 _1806 = vec2(_1728 + 0.5, 0.5 - _1735);\n        vec2 _1816 = vec2(dot(_1723, _1612), dot(_1730, _1612));\n        vec2 _1826 = vec2(dot(_1723, _1615), dot(_1730, _1615));\n        int param_8 = _1690 + 5;\n        vec4 _1831 = fa_light_texel(param_8);\n        int param_9 = _1690 + 3;\n        vec4 _1836 = fa_light_texel(param_9);\n        int param_10 = _1690 + 4;\n        vec4 _1841 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1831.xyz;\n        bool _1851 = _1836.z > _1836.x;\n        if (_1851)\n        {\n            vec4 param_11 = _1836;\n            vec2 param_12 = _1806;\n            vec2 param_13 = _1640;\n            vec2 param_14 = _1816;\n            vec2 param_15 = _1826;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1650 > 0.5) && (_1650 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1877 = fa_dc_to_linear(param_16);\n                vec4 _4918 = tx;\n                _4918.x = _1877.x;\n                _4918.y = _1877.y;\n                _4918.z = _1877.z;\n                tx = _4918;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1798 * tex_a) * _1831.w, 0.0, 1.0)));\n        if (_1841.z > _1841.x)\n        {\n            vec4 param_17 = _1841;\n            vec2 param_18 = _1806;\n            vec2 param_19 = _1640;\n            vec2 param_20 = _1816;\n            vec2 param_21 = _1826;\n            vec4 _1921 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1650 > 1.5)\n            {\n                vec3 param_22 = _1921.xyz;\n                vec3 _1931 = fa_dc_to_srgb(param_22);\n                _1925 = _1931;\n            }\n            else\n            {\n                _1925 = _1921.xyz;\n            }\n            vec3 _1940 = (_1925 * 2.0) - vec3(1.0);\n            vec2 _1945 = _1940.xy * _1695.y;\n            vec3 _1967 = (normalize(_1723) * _1945.x) + (normalize(_1730) * _1945.y);\n            vec3 _1970 = normalize(normal);\n            normal = normalize(mix(_1970, normalize((_1970 * max(_1940.z, 0.0500000007450580596923828125)) + (_1967 - (_1970 * dot(_1970, _1967)))), vec3(clamp(_1798 * (_1851 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[39].y > 0.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3165 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3165;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3221 = (1.0 - fa_mesh_fs_params[40].w) - fa_mesh_fs_params[45].w;\n    vec3 amb = vec3(0.0);\n    bool _3227 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3221 > 0.0005000000237487256526947021484375)\n    {\n        if (_3227)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[39].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3221;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3221;\n        }\n    }\n    bool _3280 = fa_mesh_fs_params[40].w > 0.0;\n    if (_3280)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[40].xy;\n            float param_4 = fa_mesh_fs_params[40].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[40].w);\n        }\n    }\n    bool _3311 = fa_mesh_fs_params[45].w > 0.0;\n    if (_3311)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[45].xy;\n            float param_7 = fa_mesh_fs_params[45].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[45].w);\n        }\n    }\n    if ((_3227 || _3280) || _3311)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[30].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 30].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[30].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3620;\n    if (fa_lm.z > 0.5)\n    {\n        _3620 = 0.0;\n    }\n    else\n    {\n        _3620 = 1.0 - clamp(fa_mesh_fs_params[30].w, 0.0, 1.0);\n    }\n    bool _3631 = _3620 < 1.0;\n    bool _3637;\n    if (_3631)\n    {\n        int param = li;\n        _3637 = fa_light_baked(param);\n    }\n    else\n    {\n        _3637 = _3631;\n    }\n    return _3637 ? _3620 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _573 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _586 = (c - (ru * hx)) - p;\n        vec3 _592 = ru * (2.0 * hx);\n        float _598 = max(dot(_592, _592), 9.9999999392252902907785028219223e-09);\n        float _602 = dot(_586, _592);\n        float t = clamp((-_602) / _598, 0.0, 1.0);\n        if (_573)\n        {\n            float _617 = dot(r, _592);\n            float _623 = _598 - (_617 * _617);\n            if (abs(_623) > (9.9999997473787516355514526367188e-06 * _598))\n            {\n                t = clamp(((dot(r, _586) * _617) - _602) / _623, 0.0, 1.0);\n            }\n        }\n        return (p + _586) + (_592 * t);\n    }\n    vec3 q = p;\n    float _655 = dot(r, axis);\n    bool _663;\n    if (_573)\n    {\n        _663 = abs(_655) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _663 = _573;\n    }\n    if (_663)\n    {\n        float _673 = dot(c - p, axis) / _655;\n        if (_673 > 0.0)\n        {\n            q = p + (r * _673);\n        }\n    }\n    vec3 _686 = q - c;\n    vec2 xy = vec2(dot(_686, ru), dot(_686, uu));\n    if (shape > 0.5)\n    {\n        float _701 = length(xy);\n        if (_701 > hx)\n        {\n            xy *= (hx / _701);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _343 = abs(d);\n    float _345 = _343.x;\n    float _347 = _343.y;\n    bool _348 = _345 >= _347;\n    bool _356;\n    if (_348)\n    {\n        _356 = _345 >= _343.z;\n    }\n    else\n    {\n        _356 = _348;\n    }\n    int _357;\n    if (_356)\n    {\n        _357 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _372;\n        if (_347 >= _343.z)\n        {\n            _372 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _372 = (d.z > 0.0) ? 4 : 5;\n        }\n        _357 = _372;\n    }\n    return _357;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _493 = dot(d, right);\n    float _497 = dot(d, up);\n    float _508;\n    if (((_493 * _493) + (_497 * _497)) > 1.0000000133514319600180897396058e-10)\n    {\n        _508 = atan(_497, _493) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _508 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_508 - floor(_508)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _739 = fa_light_base(param);\n    bool _743 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _739;\n    vec4 _747 = fa_light_texel(param_1);\n    int param_2 = _739 + 1;\n    vec4 _752 = fa_light_texel(param_2);\n    float _755 = _752.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _767 = _743 && (_755 > 2.5);\n    fa_light_is_area = _767;\n    bool _769 = _755 < 0.5;\n    vec3 l;\n    if (_769)\n    {\n        l = normalize(_747.xyz);\n        if (_743)\n        {\n            int param_3 = _739 + 6;\n            vec4 _783 = fa_light_texel(param_3);\n            if (_783.z > 0.5)\n            {\n                int param_4 = _739 + 4;\n                vec4 _793 = fa_light_texel(param_4);\n                int param_5 = _739 + 5;\n                vec4 _798 = fa_light_texel(param_5);\n                vec2 param_6 = _783.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _793.xyz) * _793.w, (-dot(world_pos, _798.xyz)) * _798.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _828 = _747.xyz;\n        vec3 _830 = _828 - world_pos;\n        vec3 to_light = _830;\n        float _833 = length(_830);\n        float reach = _833;\n        bool front = true;\n        if (_767)\n        {\n            int param_8 = _739 + 7;\n            reach = max(_833 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _739 + 4;\n            vec4 _857 = fa_light_texel(param_9);\n            int param_10 = _739 + 5;\n            vec4 _862 = fa_light_texel(param_10);\n            int param_11 = _739 + 6;\n            vec4 _867 = fa_light_texel(param_11);\n            float _868 = _867.w;\n            int param_12 = _739 + 2;\n            vec3 _875 = normalize(fa_light_texel(param_12).xyz);\n            bool _877 = _868 > 1.5;\n            bool _885;\n            if (!_877)\n            {\n                _885 = dot(_875, to_light) < 0.0;\n            }\n            else\n            {\n                _885 = _877;\n            }\n            front = _885;\n            vec3 r = vec3(0.0);\n            vec3 _894 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _898 = dot(n, n) > 0.5;\n            bool _906;\n            if (_898)\n            {\n                _906 = dot(_894, _894) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _906 = _898;\n            }\n            if (_906)\n            {\n                r = reflect(-normalize(_894), normalize(n));\n            }\n            vec3 param_13 = _828;\n            vec3 param_14 = _875;\n            vec3 param_15 = _857.xyz;\n            vec3 param_16 = _862.xyz;\n            float param_17 = _857.w;\n            float param_18 = _862.w;\n            float param_19 = _868;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _942 = length(to_light);\n        dist = _942;\n        l = to_light / vec3(max(_942, 9.9999997473787516355514526367188e-05));\n        float _956 = reach / max(_747.w, 0.001000000047497451305389404296875);\n        float _962 = clamp(1.0 - (_956 * _956), 0.0, 1.0);\n        float _964;\n        if (front)\n        {\n            _964 = _962 * _962;\n        }\n        else\n        {\n            _964 = 0.0;\n        }\n        atten = _964;\n        bool _975 = _755 < 2.5;\n        if ((_755 > 1.5) && _975)\n        {\n            int param_22 = _739 + 2;\n            vec4 _983 = fa_light_texel(param_22);\n            float _993 = _983.w;\n            int param_23 = _739 + 3;\n            vec4 _998 = fa_light_texel(param_23);\n            float _999 = _998.x;\n            float cos_inner = _999;\n            if (_999 > 1.5)\n            {\n                cos_inner = mix(_993, 1.0, 0.25);\n            }\n            atten *= smoothstep(_993, cos_inner, dot(-l, normalize(_983.xyz)));\n        }\n        if (_743 && (_755 < 1.5))\n        {\n            int param_24 = _739 + 6;\n            vec4 _1023 = fa_light_texel(param_24);\n            if (_1023.z > 0.5)\n            {\n                vec3 _1031 = -to_light;\n                int param_25 = _739 + 4;\n                int param_26 = _739 + 5;\n                vec3 _1045 = fa_light_texel(param_25).xyz;\n                vec3 _1049 = fa_light_texel(param_26).xyz;\n                vec3 _1058 = vec3(dot(_1031, _1045), dot(_1031, _1049), dot(_1031, cross(_1045, _1049)));\n                vec3 param_27 = _1058;\n                int _1062 = fa_cube_face(param_27);\n                int param_28 = _1062;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1089 = vec2(dot(_1058, cross(param_29, param_30)), dot(_1058, param_30)) / vec2(max(dot(_1058, param_29), 9.9999997473787516355514526367188e-05));\n                int _1093 = _1062 / 3;\n                vec2 param_31 = _1023.xy + (vec2(float(_1062 - (_1093 * 3)), float(_1093)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1089.x), 0.5 - (0.5 * _1089.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _739 + 7;\n            vec4 _1123 = fa_light_texel(param_33);\n            if (_1123.z > 0.5)\n            {\n                int param_34 = _739 + 2;\n                int param_35 = _739 + 4;\n                int param_36 = _739 + 5;\n                vec2 param_37 = _1123.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_743 && _975)\n            {\n                int param_42 = _739 + 6;\n                vec4 _1170 = fa_light_texel(param_42);\n                int param_43 = _739 + 7;\n                vec4 _1175 = fa_light_texel(param_43);\n                bool _1178 = _1170.z > 0.5;\n                bool _1185;\n                if (!_1178)\n                {\n                    _1185 = _1175.z > 0.5;\n                }\n                else\n                {\n                    _1185 = _1178;\n                }\n                if (_1185)\n                {\n                    int param_44 = _739 + 2;\n                    vec4 _1192 = fa_light_texel(param_44);\n                    vec3 _1196 = normalize(_1192.xyz);\n                    int param_45 = _739 + 4;\n                    vec4 _1201 = fa_light_texel(param_45);\n                    int param_46 = _739 + 5;\n                    vec4 _1206 = fa_light_texel(param_46);\n                    if (_1178)\n                    {\n                        vec3 _1214 = -to_light;\n                        float _1221 = _1192.w;\n                        float _1237 = 0.5 / max(dot(_1214, _1196) * (sqrt(max(1.0 - (_1221 * _1221), 0.0)) / max(_1221, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1170.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1214, _1201.xyz) * _1237), 0.5 - (dot(_1214, _1206.xyz) * _1237));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1175.z > 0.5)\n                    {\n                        vec2 param_49 = _1175.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1196;\n                        vec3 param_52 = _1201.xyz;\n                        vec3 param_53 = _1206.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _4792 = _752.xyz * atten;\n    if (_743)\n    {\n        _4792 *= fa_light_tint;\n    }\n    int _1305;\n    if (_769)\n    {\n        _1305 = 0;\n    }\n    else\n    {\n        _1305 = ((_755 > 1.5) && (_755 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4792, atten, 1.0, dist, _1305);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2042;\n    if (i == 0)\n    {\n        _2042 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2058;\n        if (i == 1)\n        {\n            _2058 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2066;\n            if (i == 2)\n            {\n                _2066 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2066 = fa_shadows[24].w;\n            }\n            _2058 = _2066;\n        }\n        _2042 = _2058;\n    }\n    return _2042;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2099 = fa_shadow_depth(param, param_1);\n    float _2103;\n    if (conv.x < 0.5)\n    {\n        _2103 = _2099;\n    }\n    else\n    {\n        _2103 = (conv.y * conv.z) / (conv.z - (_2099 * (conv.z - conv.y)));\n    }\n    return _2103;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2030 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2030), sin(_2030)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2149 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2158;\n        if (k < 0.0)\n        {\n            _2158 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2158 = k;\n        }\n        float _2178 = clamp((_2158 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2149;\n            vec2 _2197 = fa_shadow_vogel(param_3, param_4, param_5) * _2178;\n            vec2 param_6 = uv + (_2197 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2209 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2209 < (zr - (length(_2197) * plane)))\n            {\n                sum += _2209;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2235 = sum / cnt;\n        float _2245;\n        if (k < 0.0)\n        {\n            _2245 = (-k) / max(_2235, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2245 = k;\n        }\n        radius = clamp(((max(zr - _2235, 0.0) * unit) * _2245) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2267 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2267; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2267;\n        float param_11 = _2149;\n        vec2 _2286 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2286 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2286) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2267);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2328 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2333 = clamp(dot(n, l), 0.0, 1.0);\n    float _2339 = sqrt(1.0 - (_2333 * _2333));\n    float _2346 = min(_2339 / max(_2333, 0.20000000298023223876953125), 4.0);\n    float _2351;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2351 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2351 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2376 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2351 * _2339)), 1.0);\n    float _2383 = _2376.x;\n    bool _2386 = _2383 < fa_shadows[ci * 1 + 16].x;\n    bool _2395;\n    if (!_2386)\n    {\n        _2395 = _2383 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2395 = _2386;\n    }\n    bool _2404;\n    if (!_2395)\n    {\n        _2404 = _2376.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2404 = _2395;\n    }\n    bool _2413;\n    if (!_2404)\n    {\n        _2413 = _2376.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2413 = _2404;\n    }\n    bool _2420;\n    if (!_2413)\n    {\n        _2420 = _2376.z > 1.0;\n    }\n    else\n    {\n        _2420 = _2413;\n    }\n    if (_2420)\n    {\n        return -1.0;\n    }\n    float _2428;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2428 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2428 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2376.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2376.z - ((_2428 * (1.0 + (0.5 * _2346))) / _2328);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2328;\n    float param_5 = _2328 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2346, 3.0)) * 0.5) / _2328;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2806 = int(fa_shadows[25].x + 0.5);\n    if (_2806 < 1)\n    {\n        return 1.0;\n    }\n    float _2821 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2806 - 1;\n    if (_2821 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2833 = _2806 > 1;\n    bool _2840;\n    if (_2833)\n    {\n        _2840 = _2821 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2840 = _2833;\n    }\n    if (_2840)\n    {\n        ci = 1;\n    }\n    bool _2844 = _2806 > 2;\n    bool _2851;\n    if (_2844)\n    {\n        _2851 = _2821 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2851 = _2844;\n    }\n    if (_2851)\n    {\n        ci = 2;\n    }\n    bool _2855 = _2806 > 3;\n    bool _2862;\n    if (_2855)\n    {\n        _2862 = _2821 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2862 = _2855;\n    }\n    if (_2862)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2806)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2888 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2888;\n        if (_2888 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2913;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2913 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2913 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2932 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2913, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2943 = clamp((_2821 - (fa_shadow_split_at(param_7) - _2932)) / _2932, 0.0, 1.0);\n        if (_2943 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2806)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2964 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2964;\n                if (_2964 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2943);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2486 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2493;\n    if (!_2486)\n    {\n        _2493 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2493 = _2486;\n    }\n    if (_2493)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2506 = fa_light_texel(param);\n    float _2507 = _2506.x;\n    if (_2507 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2516 = int(_2507 + 0.5);\n    int param_1 = _2516;\n    vec4 _2520 = fa_light_texel(param_1);\n    int param_2 = _2516 + 1;\n    vec4 _2525 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2528 = _2520.y;\n    if (_2528 > 0.0)\n    {\n        float _2545 = 1.0 - smoothstep(0.75 * _2528, _2528, length(world - fa_shadows[27].xyz));\n        fade = _2545;\n        if (_2545 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2520.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2569 = (_2516 + 2) + (face * 6);\n    int param_4 = _2569;\n    int param_5 = _2569 + 1;\n    int param_6 = _2569 + 3;\n    vec4 _2583 = fa_light_texel(param_6);\n    int param_7 = _2569 + 4;\n    vec4 _2588 = fa_light_texel(param_7);\n    int param_8 = _2569 + 5;\n    vec4 _2593 = fa_light_texel(param_8);\n    float _2605 = _2593.x * max(dot(_2583, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2610 = clamp(dot(n, l), 0.0, 1.0);\n    float _2633 = clamp(dot(n, _2583.xyz), -1.0, 1.0);\n    float _2652 = min(sqrt(1.0 - (_2633 * _2633)) / max(abs(dot(n, world - lpos)) / max(dot(_2583, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2655 = _2525.y;\n    float _2657;\n    if (_2655 > 0.0)\n    {\n        _2657 = _2655;\n    }\n    else\n    {\n        _2657 = 1.5 * _2605;\n    }\n    vec4 _2677 = vec4(world + (n * (_2657 * sqrt(1.0 - (_2610 * _2610)))), 1.0);\n    float _2681 = dot(_2583, _2677);\n    float _2684 = _2593.y;\n    if (_2681 < _2684)\n    {\n        return 1.0;\n    }\n    vec2 _2699 = vec2(dot(fa_light_texel(param_4), _2677), dot(fa_light_texel(param_5), _2677)) / vec2(_2681);\n    float _2701 = _2699.x;\n    bool _2704 = _2701 < _2588.x;\n    bool _2713;\n    if (!_2704)\n    {\n        _2713 = _2701 > _2588.z;\n    }\n    else\n    {\n        _2713 = _2704;\n    }\n    bool _2722;\n    if (!_2713)\n    {\n        _2722 = _2699.y < _2588.y;\n    }\n    else\n    {\n        _2722 = _2713;\n    }\n    bool _2731;\n    if (!_2722)\n    {\n        _2731 = _2699.y > _2588.w;\n    }\n    else\n    {\n        _2731 = _2722;\n    }\n    if (_2731)\n    {\n        return 1.0;\n    }\n    float _2737 = _2525.x;\n    float _2739;\n    if (_2737 > 0.0)\n    {\n        _2739 = _2737;\n    }\n    else\n    {\n        _2739 = 1.5 * _2605;\n    }\n    vec2 param_9 = _2699;\n    vec4 param_10 = _2588;\n    float param_11 = _2681 - (_2739 * (1.0 + (0.5 * _2652)));\n    float param_12 = _2605;\n    float param_13 = 1.0;\n    float param_14 = _2593.z * 0.25;\n    float param_15 = (_2605 * min(_2652, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2684, _2593.z);\n    int param_17 = int(_2520.z + 0.5);\n    float param_18 = _2520.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3362 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3369;\n    if (!_3362)\n    {\n        _3369 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3369 = _3362;\n    }\n    if (_3369)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3382 = fa_light_texel(param);\n    float _3383 = _3382.y;\n    float len = _3383;\n    if (_3383 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3395 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3405 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3395);\n    if (_3405 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3411 = len;\n    float _3414 = min(_3411, 0.89999997615814208984375 * dist);\n    len = _3414;\n    float _3420 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3395);\n    float _3425 = _3420 + (0.5 * _3414);\n    vec3 _3431 = world + (gn * _3420);\n    float _3433 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3498;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3449 = (float(k) + _3433) * 0.083333335816860198974609375;\n        vec3 _3457 = _3431 + (l * (_3449 * len));\n        vec4 _3463 = vec4(_3457, 1.0);\n        float _3469 = dot(fa_mesh_fs_params[28], _3463);\n        if (_3469 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3489 = vec2(dot(fa_mesh_fs_params[26], _3463), dot(fa_mesh_fs_params[27], _3463)) / vec2(_3469);\n        float _3493 = _3489.x * 0.5;\n        float _3494 = _3493 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3498 = (_3489.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3498 = 0.5 - (_3489.y * 0.5);\n        }\n        bool _3514 = _3494 < 0.0;\n        bool _3521;\n        if (!_3514)\n        {\n            _3521 = _3494 >= 1.0;\n        }\n        else\n        {\n            _3521 = _3514;\n        }\n        bool _3528;\n        if (!_3521)\n        {\n            _3528 = _3498 < 0.0;\n        }\n        else\n        {\n            _3528 = _3521;\n        }\n        bool _3535;\n        if (!_3528)\n        {\n            _3535 = _3498 >= 1.0;\n        }\n        else\n        {\n            _3535 = _3528;\n        }\n        if (_3535)\n        {\n            break;\n        }\n        vec4 _3554 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_3494, _3498) * fa_mesh_fs_params[24].zw), 0);\n        if (_3554.w < 0.5)\n        {\n            continue;\n        }\n        float _3573 = (dot(fa_mesh_fs_params[29].xyz, _3457) + fa_mesh_fs_params[29].w) - _3554.x;\n        if ((_3573 > _3420) && (_3573 < _3425))\n        {\n            occ = max(occ, (1.0 - (_3449 * _3449)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3494, 0.5 - _3493), min(_3498, 1.0 - _3498))));\n        }\n    }\n    return 1.0 - (occ * _3405);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _3676 = fa_baked_keep(param);\n    if (_3676 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3702 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _4818 = _3702.color;\n    float _4819 = _3702.attenuation;\n    float _4820 = _3702.shadow;\n    bool _3705 = _3702.type == 0;\n    if (_3705 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3702.direction;\n        float _3716 = fa_shadow_factor(param_5, param_6);\n        _4820 = _3716;\n        _4818 *= _3716;\n    }\n    else\n    {\n        bool _3727 = _3702.type != 0;\n        bool _3733;\n        if (_3727)\n        {\n            _3733 = _4819 > 0.0;\n        }\n        else\n        {\n            _3733 = _3727;\n        }\n        if (_3733)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3702.direction;\n            float _3752 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4820 = _3752;\n            _4818 *= _3752;\n        }\n    }\n    bool _3762 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3768;\n    if (_3762)\n    {\n        _3768 = _4819 > 0.0;\n    }\n    else\n    {\n        _3768 = _3762;\n    }\n    if (_3768)\n    {\n        float _3775;\n        if (_3705)\n        {\n            _3775 = 1000000000.0;\n        }\n        else\n        {\n            _3775 = _3702._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _3702.direction;\n        float param_18 = _3775;\n        float _3793 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _4820 *= _3793;\n        _4818 *= _3793;\n    }\n    float _3806 = _4819;\n    float _3807 = _3806 * _3676;\n    _4819 = _3807;\n    vec3 _3811 = _4818;\n    vec3 _3812 = _3811 * _3676;\n    _4818 = _3812;\n    return LightSample(_3702.direction, _3812, _3807, _4820, _3702._distance, _3702.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _3826;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _3826 = 1.0;\n    }\n    else\n    {\n        _3826 = fa_material[0].x;\n    }\n    return (s.albedo * l.color) * _3826;\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2988 = int(fa_shadows[25].x + 0.5);\n    float _2998 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3003 = _2988 > 0;\n    bool _3012;\n    if (_3003)\n    {\n        int param = _2988 - 1;\n        _3012 = _2998 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3012 = _3003;\n    }\n    if (_3012)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3018 = _2988 > 1;\n        bool _3025;\n        if (_3018)\n        {\n            _3025 = _2998 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3025 = _3018;\n        }\n        if (_3025)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3031 = _2988 > 2;\n        bool _3038;\n        if (_3031)\n        {\n            _3038 = _2998 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3038 = _3031;\n        }\n        if (_3038)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3044 = _2988 > 3;\n        bool _3051;\n        if (_3044)\n        {\n            _3051 = _2998 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3051 = _3044;\n        }\n        if (_3051)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4659 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4659 = -_4659;\n    }\n    vec3 _4250 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4659, fa_world_tangent, fa_uv, fa_vertex_color, _4250, gl_FrontFacing);\n    Surface _4258 = fa_standard_surface(param_1);\n    vec3 _4690 = _4258.albedo;\n    float _4691 = _4258.alpha;\n    vec3 _4692 = _4258.normal;\n    float _4693 = _4258.metallic;\n    float _4694 = _4258.roughness;\n    float _4695 = _4258.occlusion;\n    vec3 _4696 = _4258.emission;\n    float _4697 = _4258.clearcoat;\n    float _4698 = _4258.clearcoat_roughness;\n    vec3 _4699 = _4258.sheen_color;\n    float _4700 = _4258.sheen_roughness;\n    float _4701 = _4258.anisotropy;\n    float _4702 = _4258.anisotropy_rotation;\n    float _4703 = _4258.specular;\n    float _4704 = _4258.ior;\n    vec3 _4705 = _4258.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4659, fa_world_tangent, fa_uv, fa_vertex_color, _4250, gl_FrontFacing);\n    Surface param_3 = _4258;\n    surface(param_2, param_3);\n    _4690 = param_3.albedo;\n    _4691 = param_3.alpha;\n    _4692 = param_3.normal;\n    _4693 = param_3.metallic;\n    _4694 = param_3.roughness;\n    _4695 = param_3.occlusion;\n    _4696 = param_3.emission;\n    _4697 = param_3.clearcoat;\n    _4698 = param_3.clearcoat_roughness;\n    _4699 = param_3.sheen_color;\n    _4700 = param_3.sheen_roughness;\n    _4701 = param_3.anisotropy;\n    _4702 = param_3.anisotropy_rotation;\n    _4703 = param_3.specular;\n    _4704 = param_3.ior;\n    _4705 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4659;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4690 = param_6;\n    _4692 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4690;\n    }\n    else\n    {\n        vec3 _4296 = _4692;\n        vec3 _4297 = normalize(_4296);\n        _4692 = _4297;\n        vec3 param_8 = _4297;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _4690) * _4695;\n        int _4316 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4316; ln++)\n        {\n            int param_9 = ln;\n            int _4329 = fa_cl_light(param_9);\n            int param_10 = _4329;\n            if (fa_baked_keep(param_10) <= 0.0)\n            {\n                continue;\n            }\n            int param_11 = _4329;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _4659;\n            LightSample _4345 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _4659, fa_world_tangent, fa_uv, fa_vertex_color, _4250, gl_FrontFacing);\n            Surface param_15 = Surface(_4690, _4691, _4692, _4693, _4694, _4695, _4696, _4697, _4698, _4699, _4700, _4701, _4702, _4703, _4704, _4705);\n            LightSample param_16 = _4345;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _4360 = result;\n    vec3 _4361 = _4360 + _4696;\n    result = _4361;\n    vec3 param_17 = _4361;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _4370 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4377;\n    if (!_4370)\n    {\n        _4377 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4377 = _4370;\n    }\n    if (_4377)\n    {\n        vec3 _4386 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4392 = dot(_4386, fa_mesh_fs_params[9].xyz);\n        bool _4396 = fa_mesh_fs_params[9].w > 0.5;\n        float _4397;\n        if (_4396)\n        {\n            _4397 = _4392;\n        }\n        else\n        {\n            _4397 = length(_4386);\n        }\n        float _4409 = _4397 - fa_mesh_fs_params[8].x;\n        if (_4409 > 0.0)\n        {\n            float _4418 = fa_mesh_fs_params[7].w * _4409;\n            float tau = _4418 * _4418;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4434;\n                if (_4396)\n                {\n                    _4434 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4392);\n                }\n                else\n                {\n                    _4434 = fa_mesh_fs_params[0].y;\n                }\n                float _4455 = mix(_4434, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4397, 0.0, 1.0));\n                float _4459 = fa_world_pos.y - _4455;\n                float _4464 = _4455 - fa_mesh_fs_params[8].z;\n                float _4469 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4472 = _4464 <= 0.0;\n                bool _4473 = !_4472;\n                bool _4479;\n                if (_4473)\n                {\n                    _4479 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4479 = _4472;\n                }\n                float _4480;\n                if (_4479)\n                {\n                    _4480 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4480 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4464, 80.0));\n                }\n                bool _4507;\n                if (_4473)\n                {\n                    _4507 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4507 = _4472;\n                }\n                float _4508;\n                if (_4507)\n                {\n                    _4508 = fa_mesh_fs_params[8].y * _4464;\n                }\n                else\n                {\n                    _4508 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4464, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4533 = _4469 <= 0.0;\n                bool _4540;\n                if (!_4533)\n                {\n                    _4540 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4540 = _4533;\n                }\n                float _4541;\n                if (_4540)\n                {\n                    _4541 = fa_mesh_fs_params[8].y * _4469;\n                }\n                else\n                {\n                    _4541 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4469, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4568;\n                if (abs(_4459) < 0.001000000047497451305389404296875)\n                {\n                    _4568 = _4480;\n                }\n                else\n                {\n                    _4568 = (_4541 - _4508) / _4459;\n                }\n                tau += (_4409 * max(_4568, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4691);\n}\n\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_395",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 50,
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
            "inst_name": "_2052",
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
            "inst_name": "_3832",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _302 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[50];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _788 = base_t;\n    _788.x = _227.x;\n    _788.y = _227.y;\n    _788.z = _227.z;\n    base_t = _788;\n    vec4 _243 = (_788 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _751 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _796 = _281;\n        _796.x = _286.x;\n        _796.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _796;\n        _751 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _799 = mrt;\n    _799.x = _315.x;\n    _799.y = _315.y;\n    _799.z = _315.z;\n    mrt = _799;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _756 = fa_mesh_fs_params[20].x;\n    float _757 = fa_mesh_fs_params[20].y;\n    float _760 = fa_mesh_fs_params[20].z;\n    float _759 = fa_mesh_fs_params[21].w;\n    float _762 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _756 *= _357.y;\n            _757 *= _357.z;\n            _759 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _760 *= mrt.x;\n            _762 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _751, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _756, _757, fa_mesh_fs_params[21].xyz, _759, _760, fa_mesh_fs_params[20].w, _762, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _662 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _662 = -_662;\n    }\n    vec3 _521 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _662, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _662, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _536 = normalize(param_2.normal);\n    vec3 _551 = normalize(vec3(dot(fa_pre_r0, _536), dot(fa_pre_r1, _536), dot(fa_pre_r2, _536)));\n    float _563 = _551.z;\n    vec2 e = _551.xy / vec2((abs(_551.x) + abs(_551.y)) + abs(_563));\n    if (_563 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_215",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 50,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[50];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _788 = base_t;\n    _788.x = _227.x;\n    _788.y = _227.y;\n    _788.z = _227.z;\n    base_t = _788;\n    vec4 _243 = (_788 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _751 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _796 = _281;\n        _796.x = _286.x;\n        _796.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _796;\n        _751 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _799 = mrt;\n    _799.x = _315.x;\n    _799.y = _315.y;\n    _799.z = _315.z;\n    mrt = _799;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _756 = fa_mesh_fs_params[20].x;\n    float _757 = fa_mesh_fs_params[20].y;\n    float _760 = fa_mesh_fs_params[20].z;\n    float _759 = fa_mesh_fs_params[21].w;\n    float _762 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _756 *= _357.y;\n            _757 *= _357.z;\n            _759 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _760 *= mrt.x;\n            _762 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _751, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _756, _757, fa_mesh_fs_params[21].xyz, _759, _760, fa_mesh_fs_params[20].w, _762, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _662 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _662 = -_662;\n    }\n    vec3 _521 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _662, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _662, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _536 = normalize(param_2.normal);\n    vec3 _551 = normalize(vec3(dot(fa_pre_r0, _536), dot(fa_pre_r1, _536), dot(fa_pre_r2, _536)));\n    float _563 = _551.z;\n    vec2 e = _551.xy / vec2((abs(_551.x) + abs(_551.y)) + abs(_563));\n    if (_563 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_215",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 50,
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
