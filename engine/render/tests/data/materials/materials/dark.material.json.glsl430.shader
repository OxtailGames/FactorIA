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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1344 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1351;\n    if (!_1344)\n    {\n        _1351 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1351 = _1344;\n    }\n    bool _1359;\n    if (!_1351)\n    {\n        _1359 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1359 = _1351;\n    }\n    bool _1366;\n    if (!_1359)\n    {\n        _1366 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1366 = _1359;\n    }\n    bool _1373;\n    if (!_1366)\n    {\n        _1373 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1373 = _1366;\n    }\n    if (_1373)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1383 = vec4(world_pos, 1.0);\n    float _1389 = dot(fa_mesh_fs_params[16], _1383);\n    if (!(_1389 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1411 = vec2(dot(fa_mesh_fs_params[14], _1383), dot(fa_mesh_fs_params[15], _1383)) / vec2(_1389);\n    int _1415 = int(fa_mesh_fs_params[18].x);\n    int _1419 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1419) + clamp(int(floor(((_1411.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1419 - 1)) * _1415)) + clamp(int(floor(((_1411.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1415 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1495 = fa_cluster_texel(param);\n    return ivec2(int(_1495.x), int(_1495.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3722 = fa_cluster_lookup(param);\n    fa_cl_slot = _3722.x;\n    fa_cl_local = _3722.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3927 = fa_linear_to_srgb(param);\n        c = _3927;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3935 = fa_srgb_to_linear(param_1);\n            c = _3935;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _298;\n    if (i.front_facing)\n    {\n        _298 = i.world_normal;\n    }\n    else\n    {\n        _298 = -i.world_normal;\n    }\n    vec3 _322 = normalize(i.world_tangent.xyz - (_298 * dot(_298, i.world_tangent.xyz)));\n    vec3 _349 = normalize(((_322 * m.x) + ((cross(_298, _322) * i.world_tangent.w) * m.y)) + (_298 * m.z));\n    vec3 _352;\n    if (i.front_facing)\n    {\n        _352 = _349;\n    }\n    else\n    {\n        _352 = -_349;\n    }\n    return _352;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3966 = fa_tex_fix(param_2, param_3);\n    vec4 _5670 = base_t;\n    _5670.x = _3966.x;\n    _5670.y = _3966.y;\n    _5670.z = _3966.z;\n    base_t = _5670;\n    vec4 _3980 = (_5670 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5507 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4012 = fa_tex_fix(param_6, param_7);\n        vec3 _4015 = (_4012 * 2.0) - vec3(1.0);\n        vec2 _4020 = _4015.xy * fa_mesh_fs_params[6].x;\n        vec3 _5678 = _4015;\n        _5678.x = _4020.x;\n        _5678.y = _4020.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5678;\n        _5507 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4048 = fa_tex_fix(param_12, param_13);\n    vec4 _5681 = mrt;\n    _5681.x = _4048.x;\n    _5681.y = _4048.y;\n    _5681.z = _4048.z;\n    mrt = _5681;\n    vec4 _4076 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4076.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4087 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4117 = fa_tex_fix(param_20, param_21);\n    float _5512 = fa_mesh_fs_params[20].x;\n    float _5513 = fa_mesh_fs_params[20].y;\n    float _5516 = fa_mesh_fs_params[20].z;\n    float _5515 = fa_mesh_fs_params[21].w;\n    float _5518 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5512 *= _4087.y;\n            _5513 *= _4087.z;\n            _5515 *= _4076.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5516 *= mrt.x;\n            _5518 *= mrt.w;\n        }\n    }\n    return Surface(_3980.xyz, _3980.w, _5507, clamp(fa_mesh_fs_params[5].x * _4048.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4048.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4087.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4117), _5512, _5513, fa_mesh_fs_params[21].xyz, _5515, _5516, fa_mesh_fs_params[20].w, _5518, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1575 = rect.zw - rect.xy;\n    vec2 _1579 = _1575 * atlas;\n    vec2 _1583 = ddx * _1579;\n    vec2 _1587 = ddy * _1579;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1575), clamp(0.5 * log2(max(max(dot(_1583, _1583), dot(_1587, _1587)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1620 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1627;\n    if (!_1620)\n    {\n        _1627 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1627 = _1620;\n    }\n    if (_1627)\n    {\n        return;\n    }\n    vec3 _1633 = dFdx(world_pos);\n    vec3 _1636 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1640 = fa_cluster_texel(param);\n    int _1644 = int(_1640.w);\n    if (_1644 < 1)\n    {\n        return;\n    }\n    int _1654 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1654;\n    vec4 _1658 = fa_light_texel(param_1);\n    vec2 _1661 = _1658.yz;\n    int _1665 = int(_1658.w);\n    int param_2 = _1654 + 1;\n    vec4 _1670 = fa_light_texel(param_2);\n    float _1671 = _1670.x;\n    int _1677 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1681 = int(_1640.z);\n    vec3 _1946;\n    for (int k = 0; k < _1644; k++)\n    {\n        int _1694 = _1681 + k;\n        int param_3 = _1665 + (_1694 >> 2);\n        int _1711 = (_1654 + 2) + (int(fa_light_texel(param_3)[_1694 & 3]) * 7);\n        int param_4 = _1711 + 6;\n        vec4 _1716 = fa_light_texel(param_4);\n        if (((int(_1716.w + 0.5) >> _1677) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1711;\n        vec4 _1731 = fa_light_texel(param_5);\n        int param_6 = _1711 + 1;\n        vec4 _1736 = fa_light_texel(param_6);\n        int param_7 = _1711 + 2;\n        vec4 _1741 = fa_light_texel(param_7);\n        vec3 _1744 = _1731.xyz;\n        float _1749 = dot(_1744, world_pos) + _1731.w;\n        vec3 _1751 = _1736.xyz;\n        float _1756 = dot(_1751, world_pos) + _1736.w;\n        vec3 _1758 = _1741.xyz;\n        float _1763 = dot(_1758, world_pos) + _1741.w;\n        bool _1768 = abs(_1749) > 0.5;\n        bool _1776;\n        if (!_1768)\n        {\n            _1776 = abs(_1756) > 0.5;\n        }\n        else\n        {\n            _1776 = _1768;\n        }\n        bool _1784;\n        if (!_1776)\n        {\n            _1784 = abs(_1763) > 0.5;\n        }\n        else\n        {\n            _1784 = _1776;\n        }\n        if (_1784)\n        {\n            continue;\n        }\n        float _1799 = clamp(dot(geo_normal, normalize(_1758)) * _1716.z, 0.0, 1.0);\n        if (_1799 <= 0.0)\n        {\n            continue;\n        }\n        float _1819 = (clamp((0.5 - abs(_1763)) * 10.0, 0.0, 1.0) * _1799) * _1716.x;\n        vec2 _1827 = vec2(_1749 + 0.5, 0.5 - _1756);\n        vec2 _1837 = vec2(dot(_1744, _1633), dot(_1751, _1633));\n        vec2 _1847 = vec2(dot(_1744, _1636), dot(_1751, _1636));\n        int param_8 = _1711 + 5;\n        vec4 _1852 = fa_light_texel(param_8);\n        int param_9 = _1711 + 3;\n        vec4 _1857 = fa_light_texel(param_9);\n        int param_10 = _1711 + 4;\n        vec4 _1862 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1852.xyz;\n        bool _1872 = _1857.z > _1857.x;\n        if (_1872)\n        {\n            vec4 param_11 = _1857;\n            vec2 param_12 = _1827;\n            vec2 param_13 = _1661;\n            vec2 param_14 = _1837;\n            vec2 param_15 = _1847;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1671 > 0.5) && (_1671 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1898 = fa_dc_to_linear(param_16);\n                vec4 _5595 = tx;\n                _5595.x = _1898.x;\n                _5595.y = _1898.y;\n                _5595.z = _1898.z;\n                tx = _5595;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1819 * tex_a) * _1852.w, 0.0, 1.0)));\n        if (_1862.z > _1862.x)\n        {\n            vec4 param_17 = _1862;\n            vec2 param_18 = _1827;\n            vec2 param_19 = _1661;\n            vec2 param_20 = _1837;\n            vec2 param_21 = _1847;\n            vec4 _1942 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1671 > 1.5)\n            {\n                vec3 param_22 = _1942.xyz;\n                vec3 _1952 = fa_dc_to_srgb(param_22);\n                _1946 = _1952;\n            }\n            else\n            {\n                _1946 = _1942.xyz;\n            }\n            vec3 _1961 = (_1946 * 2.0) - vec3(1.0);\n            vec2 _1966 = _1961.xy * _1716.y;\n            vec3 _1988 = (normalize(_1744) * _1966.x) + (normalize(_1751) * _1966.y);\n            vec3 _1991 = normalize(normal);\n            normal = normalize(mix(_1991, normalize((_1991 * max(_1961.z, 0.0500000007450580596923828125)) + (_1988 - (_1991 * dot(_1991, _1988)))), vec3(clamp(_1819 * (_1872 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3186 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3186;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3206 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3209 = _3206.x;\n    float _3211 = _3206.z;\n    vec2 e = vec2(_3209, _3211);\n    if (_3206.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3211)) * ((_3209 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3209)) * ((_3211 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _4231 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _4236 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _4241 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _4246 = fa_light_texel(param_3);\n    bool _4249 = _4246.z < 0.5;\n    bool _4257;\n    if (!_4249)\n    {\n        _4257 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _4257 = _4249;\n    }\n    if (_4257)\n    {\n        return vec3(0.0);\n    }\n    float _4264 = max(_4231.w, 9.9999997473787516355514526367188e-05);\n    vec3 _4267 = _4236.xyz;\n    vec3 _4271 = _4231.xyz;\n    vec3 _4275 = (fa_world_pos - _4271) / vec3(_4264);\n    vec3 _4284 = min(_4275 + vec3(0.5), (_4267 - vec3(0.5)) - _4275);\n    float _4293 = min(_4284.x, min(_4284.y, _4284.z));\n    if (!(_4293 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4308 = _4267 - vec3(1.0);\n    vec3 _4309 = clamp(_4275, vec3(0.0), _4308);\n    vec3 _4317 = min(floor(_4309), max(_4267 - vec3(2.0), vec3(0.0)));\n    vec3 _4321 = _4309 - _4317;\n    vec3 _4333 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _4264));\n    int _4338 = int(_4241.y + 0.5);\n    vec3 sh[9];\n    for (int k = 0; k < 9; k++)\n    {\n        sh[k] = vec3(0.0);\n    }\n    float wsum = 0.0;\n    int _4356 = int(_4246.w);\n    int _4357 = 8 + _4356;\n    int _4362 = 9 + _4356;\n    float _4389;\n    float _4402;\n    float _4416;\n    for (int k_1 = 0; k_1 < _4357; k_1++)\n    {\n        float _4375 = float(k_1 & 1);\n        float _4379 = float((k_1 >> 1) & 1);\n        float _4383 = float((k_1 >> 2) & 1);\n        if (_4375 > 0.5)\n        {\n            _4389 = _4321.x;\n        }\n        else\n        {\n            _4389 = 1.0 - _4321.x;\n        }\n        if (_4379 > 0.5)\n        {\n            _4402 = _4321.y;\n        }\n        else\n        {\n            _4402 = 1.0 - _4321.y;\n        }\n        if (_4383 > 0.5)\n        {\n            _4416 = _4321.z;\n        }\n        else\n        {\n            _4416 = 1.0 - _4321.z;\n        }\n        float _4426 = (_4389 * _4402) * _4416;\n        if (!(_4426 > 0.0))\n        {\n            continue;\n        }\n        vec3 _4439 = min(_4317 + vec3(_4375, _4379, _4383), _4308);\n        int _4459 = int(((_4241.x + _4439.x) + (_4236.x * (_4439.y + (_4236.y * _4439.z)))) + 0.5);\n        vec2 _4474 = vec2(float(_4459 % _4338) * 10.0, 1024.0 + (float(_4459 / _4338) * 11.0));\n        vec2 param_4 = _4474 + vec2(9.5, 10.5);\n        vec4 _4482 = fa_gi_fetch(param_4);\n        bool _4485 = _4482.y < 0.5;\n        bool _4494;\n        if (!_4485)\n        {\n            _4494 = _4482.x > _4246.y;\n        }\n        else\n        {\n            _4494 = _4485;\n        }\n        if (_4494)\n        {\n            continue;\n        }\n        vec3 _4506 = _4333 - (_4271 + (_4439 * _4264));\n        float _4509 = length(_4506);\n        vec3 _4515 = _4506 / vec3(max(_4509, 9.9999997473787516355514526367188e-05));\n        float _4525 = max(9.9999997473787516355514526367188e-05, (dot(-_4515, n) + 1.0) * 0.5);\n        float w = _4426 * (_4525 * _4525);\n        vec3 param_5 = _4515;\n        vec2 param_6 = (_4474 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _4544 = fa_gi_fetch(param_6);\n        float _4551 = _4509 / max(_4241.z, 9.9999997473787516355514526367188e-05);\n        float _4554 = _4544.x;\n        if (_4551 > _4554)\n        {\n            float _4567 = max(_4544.y - (_4554 * _4554), 0.0);\n            float _4572 = _4551 - _4554;\n            float _4581 = _4567 / max(_4567 + (_4572 * _4572), 9.9999999600419720025001879548654e-13);\n            w *= ((_4581 * _4581) * _4581);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        for (int c = 0; c < _4362; c++)\n        {\n            vec2 param_7 = _4474 + vec2(float(c) + 0.5, 10.5);\n            sh[c] += (fa_gi_fetch(param_7).xyz * w);\n        }\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    for (int c_1 = 0; c_1 < 9; c_1++)\n    {\n        sh[c_1] /= vec3(wsum);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_4293 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _4662;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _4662 = _4246.x;\n    }\n    else\n    {\n        _4662 = 1.0;\n    }\n    vec3 param_8[9] = sh;\n    vec3 param_9 = n;\n    return fa_sh_eval(param_8, param_9) * (_4241.w * _4662);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _4686 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _4691 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _4696 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _4696) && (k < 8); k++)\n    {\n        int param = _4691 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _4686;\n        vec3 _4721 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _4726 = param_3 * left;\n        acc += (_4721 * _4726);\n        left -= _4726;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3293 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3299 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3293 > 0.0005000000237487256526947021484375)\n    {\n        if (_3299)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3293;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3293;\n        }\n    }\n    bool _3352 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3352)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3383 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3383)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3299 || _3352) || _3383)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _4755 = fa_gi_light(param, param_1);\n        if (param_1 < 0.999000012874603271484375)\n        {\n            vec3 _4764;\n            if (param_1 > 0.0)\n            {\n                vec3 param_2 = n;\n                _4764 = _4755 + (fa_ambient_light(param_2) * param_1);\n            }\n            else\n            {\n                _4764 = _4755;\n            }\n            return _4764;\n        }\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param[9] = c;\n        vec3 param_1 = n;\n        vec3 _4826 = fa_sh_eval(param, param_1);\n        if (fa_mesh_fs_params[32].w >= 1.0)\n        {\n            return _4826;\n        }\n        vec3 param_2 = n;\n        return mix(fa_realtime_or_ambient(param_2), _4826, vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3692;\n    if (fa_lm.z > 0.5)\n    {\n        _3692 = 0.0;\n    }\n    else\n    {\n        _3692 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _3703 = _3692 < 1.0;\n    bool _3709;\n    if (_3703)\n    {\n        int param = li;\n        _3709 = fa_light_baked(param);\n    }\n    else\n    {\n        _3709 = _3703;\n    }\n    return _3709 ? _3692 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _594 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _607 = (c - (ru * hx)) - p;\n        vec3 _613 = ru * (2.0 * hx);\n        float _619 = max(dot(_613, _613), 9.9999999392252902907785028219223e-09);\n        float _623 = dot(_607, _613);\n        float t = clamp((-_623) / _619, 0.0, 1.0);\n        if (_594)\n        {\n            float _638 = dot(r, _613);\n            float _644 = _619 - (_638 * _638);\n            if (abs(_644) > (9.9999997473787516355514526367188e-06 * _619))\n            {\n                t = clamp(((dot(r, _607) * _638) - _623) / _644, 0.0, 1.0);\n            }\n        }\n        return (p + _607) + (_613 * t);\n    }\n    vec3 q = p;\n    float _676 = dot(r, axis);\n    bool _684;\n    if (_594)\n    {\n        _684 = abs(_676) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _684 = _594;\n    }\n    if (_684)\n    {\n        float _694 = dot(c - p, axis) / _676;\n        if (_694 > 0.0)\n        {\n            q = p + (r * _694);\n        }\n    }\n    vec3 _707 = q - c;\n    vec2 xy = vec2(dot(_707, ru), dot(_707, uu));\n    if (shape > 0.5)\n    {\n        float _722 = length(xy);\n        if (_722 > hx)\n        {\n            xy *= (hx / _722);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _514 = dot(d, right);\n    float _518 = dot(d, up);\n    float _529;\n    if (((_514 * _514) + (_518 * _518)) > 1.0000000133514319600180897396058e-10)\n    {\n        _529 = atan(_518, _514) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _529 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_529 - floor(_529)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _364 = abs(d);\n    float _366 = _364.x;\n    float _368 = _364.y;\n    bool _369 = _366 >= _368;\n    bool _377;\n    if (_369)\n    {\n        _377 = _366 >= _364.z;\n    }\n    else\n    {\n        _377 = _369;\n    }\n    int _378;\n    if (_377)\n    {\n        _378 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _393;\n        if (_368 >= _364.z)\n        {\n            _393 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _393 = (d.z > 0.0) ? 4 : 5;\n        }\n        _378 = _393;\n    }\n    return _378;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _760 = fa_light_base(param);\n    bool _764 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _760;\n    vec4 _768 = fa_light_texel(param_1);\n    int param_2 = _760 + 1;\n    vec4 _773 = fa_light_texel(param_2);\n    float _776 = _773.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _788 = _764 && (_776 > 2.5);\n    fa_light_is_area = _788;\n    bool _790 = _776 < 0.5;\n    vec3 l;\n    if (_790)\n    {\n        l = normalize(_768.xyz);\n        if (_764)\n        {\n            int param_3 = _760 + 6;\n            vec4 _804 = fa_light_texel(param_3);\n            if (_804.z > 0.5)\n            {\n                int param_4 = _760 + 4;\n                vec4 _814 = fa_light_texel(param_4);\n                int param_5 = _760 + 5;\n                vec4 _819 = fa_light_texel(param_5);\n                vec2 param_6 = _804.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _814.xyz) * _814.w, (-dot(world_pos, _819.xyz)) * _819.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _849 = _768.xyz;\n        vec3 _851 = _849 - world_pos;\n        vec3 to_light = _851;\n        float _854 = length(_851);\n        float reach = _854;\n        bool front = true;\n        if (_788)\n        {\n            int param_8 = _760 + 7;\n            reach = max(_854 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _760 + 4;\n            vec4 _878 = fa_light_texel(param_9);\n            int param_10 = _760 + 5;\n            vec4 _883 = fa_light_texel(param_10);\n            int param_11 = _760 + 6;\n            vec4 _888 = fa_light_texel(param_11);\n            float _889 = _888.w;\n            int param_12 = _760 + 2;\n            vec3 _896 = normalize(fa_light_texel(param_12).xyz);\n            bool _898 = _889 > 1.5;\n            bool _906;\n            if (!_898)\n            {\n                _906 = dot(_896, to_light) < 0.0;\n            }\n            else\n            {\n                _906 = _898;\n            }\n            front = _906;\n            vec3 r = vec3(0.0);\n            vec3 _915 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _919 = dot(n, n) > 0.5;\n            bool _927;\n            if (_919)\n            {\n                _927 = dot(_915, _915) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _927 = _919;\n            }\n            if (_927)\n            {\n                r = reflect(-normalize(_915), normalize(n));\n            }\n            vec3 param_13 = _849;\n            vec3 param_14 = _896;\n            vec3 param_15 = _878.xyz;\n            vec3 param_16 = _883.xyz;\n            float param_17 = _878.w;\n            float param_18 = _883.w;\n            float param_19 = _889;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _963 = length(to_light);\n        dist = _963;\n        l = to_light / vec3(max(_963, 9.9999997473787516355514526367188e-05));\n        float _977 = reach / max(_768.w, 0.001000000047497451305389404296875);\n        float _983 = clamp(1.0 - (_977 * _977), 0.0, 1.0);\n        float _985;\n        if (front)\n        {\n            _985 = _983 * _983;\n        }\n        else\n        {\n            _985 = 0.0;\n        }\n        atten = _985;\n        bool _996 = _776 < 2.5;\n        if ((_776 > 1.5) && _996)\n        {\n            int param_22 = _760 + 2;\n            vec4 _1004 = fa_light_texel(param_22);\n            float _1014 = _1004.w;\n            int param_23 = _760 + 3;\n            vec4 _1019 = fa_light_texel(param_23);\n            float _1020 = _1019.x;\n            float cos_inner = _1020;\n            if (_1020 > 1.5)\n            {\n                cos_inner = mix(_1014, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1014, cos_inner, dot(-l, normalize(_1004.xyz)));\n        }\n        if (_764 && (_776 < 1.5))\n        {\n            int param_24 = _760 + 6;\n            vec4 _1044 = fa_light_texel(param_24);\n            if (_1044.z > 0.5)\n            {\n                vec3 _1052 = -to_light;\n                int param_25 = _760 + 4;\n                int param_26 = _760 + 5;\n                vec3 _1066 = fa_light_texel(param_25).xyz;\n                vec3 _1070 = fa_light_texel(param_26).xyz;\n                vec3 _1079 = vec3(dot(_1052, _1066), dot(_1052, _1070), dot(_1052, cross(_1066, _1070)));\n                vec3 param_27 = _1079;\n                int _1083 = fa_cube_face(param_27);\n                int param_28 = _1083;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1110 = vec2(dot(_1079, cross(param_29, param_30)), dot(_1079, param_30)) / vec2(max(dot(_1079, param_29), 9.9999997473787516355514526367188e-05));\n                int _1114 = _1083 / 3;\n                vec2 param_31 = _1044.xy + (vec2(float(_1083 - (_1114 * 3)), float(_1114)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1110.x), 0.5 - (0.5 * _1110.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _760 + 7;\n            vec4 _1144 = fa_light_texel(param_33);\n            if (_1144.z > 0.5)\n            {\n                int param_34 = _760 + 2;\n                int param_35 = _760 + 4;\n                int param_36 = _760 + 5;\n                vec2 param_37 = _1144.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_764 && _996)\n            {\n                int param_42 = _760 + 6;\n                vec4 _1191 = fa_light_texel(param_42);\n                int param_43 = _760 + 7;\n                vec4 _1196 = fa_light_texel(param_43);\n                bool _1199 = _1191.z > 0.5;\n                bool _1206;\n                if (!_1199)\n                {\n                    _1206 = _1196.z > 0.5;\n                }\n                else\n                {\n                    _1206 = _1199;\n                }\n                if (_1206)\n                {\n                    int param_44 = _760 + 2;\n                    vec4 _1213 = fa_light_texel(param_44);\n                    vec3 _1217 = normalize(_1213.xyz);\n                    int param_45 = _760 + 4;\n                    vec4 _1222 = fa_light_texel(param_45);\n                    int param_46 = _760 + 5;\n                    vec4 _1227 = fa_light_texel(param_46);\n                    if (_1199)\n                    {\n                        vec3 _1235 = -to_light;\n                        float _1242 = _1213.w;\n                        float _1258 = 0.5 / max(dot(_1235, _1217) * (sqrt(max(1.0 - (_1242 * _1242), 0.0)) / max(_1242, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1191.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1235, _1222.xyz) * _1258), 0.5 - (dot(_1235, _1227.xyz) * _1258));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1196.z > 0.5)\n                    {\n                        vec2 param_49 = _1196.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1217;\n                        vec3 param_52 = _1222.xyz;\n                        vec3 param_53 = _1227.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5461 = _773.xyz * atten;\n    if (_764)\n    {\n        _5461 *= fa_light_tint;\n    }\n    int _1326;\n    if (_790)\n    {\n        _1326 = 0;\n    }\n    else\n    {\n        _1326 = ((_776 > 1.5) && (_776 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5461, atten, 1.0, dist, _1326);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2120 = fa_shadow_depth(param, param_1);\n    float _2124;\n    if (conv.x < 0.5)\n    {\n        _2124 = _2120;\n    }\n    else\n    {\n        _2124 = (conv.y * conv.z) / (conv.z - (_2120 * (conv.z - conv.y)));\n    }\n    return _2124;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2051 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2051), sin(_2051)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2170 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2179;\n        if (k < 0.0)\n        {\n            _2179 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2179 = k;\n        }\n        float _2199 = clamp((_2179 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2170;\n            vec2 _2218 = fa_shadow_vogel(param_3, param_4, param_5) * _2199;\n            vec2 param_6 = uv + (_2218 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2230 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2230 < (zr - (length(_2218) * plane)))\n            {\n                sum += _2230;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2256 = sum / cnt;\n        float _2266;\n        if (k < 0.0)\n        {\n            _2266 = (-k) / max(_2256, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2266 = k;\n        }\n        radius = clamp(((max(zr - _2256, 0.0) * unit) * _2266) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2288 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2288; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2288;\n        float param_11 = _2170;\n        vec2 _2307 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2307 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2307) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2288);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2507 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2514;\n    if (!_2507)\n    {\n        _2514 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2514 = _2507;\n    }\n    if (_2514)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2527 = fa_light_texel(param);\n    float _2528 = _2527.x;\n    if (_2528 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2537 = int(_2528 + 0.5);\n    int param_1 = _2537;\n    vec4 _2541 = fa_light_texel(param_1);\n    int param_2 = _2537 + 1;\n    vec4 _2546 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2549 = _2541.y;\n    if (_2549 > 0.0)\n    {\n        float _2566 = 1.0 - smoothstep(0.75 * _2549, _2549, length(world - fa_shadows[27].xyz));\n        fade = _2566;\n        if (_2566 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2541.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2590 = (_2537 + 2) + (face * 6);\n    int param_4 = _2590;\n    int param_5 = _2590 + 1;\n    int param_6 = _2590 + 3;\n    vec4 _2604 = fa_light_texel(param_6);\n    int param_7 = _2590 + 4;\n    vec4 _2609 = fa_light_texel(param_7);\n    int param_8 = _2590 + 5;\n    vec4 _2614 = fa_light_texel(param_8);\n    float _2626 = _2614.x * max(dot(_2604, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2631 = clamp(dot(n, l), 0.0, 1.0);\n    float _2654 = clamp(dot(n, _2604.xyz), -1.0, 1.0);\n    float _2673 = min(sqrt(1.0 - (_2654 * _2654)) / max(abs(dot(n, world - lpos)) / max(dot(_2604, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2676 = _2546.y;\n    float _2678;\n    if (_2676 > 0.0)\n    {\n        _2678 = _2676;\n    }\n    else\n    {\n        _2678 = 1.5 * _2626;\n    }\n    vec4 _2698 = vec4(world + (n * (_2678 * sqrt(1.0 - (_2631 * _2631)))), 1.0);\n    float _2702 = dot(_2604, _2698);\n    float _2705 = _2614.y;\n    if (_2702 < _2705)\n    {\n        return 1.0;\n    }\n    vec2 _2720 = vec2(dot(fa_light_texel(param_4), _2698), dot(fa_light_texel(param_5), _2698)) / vec2(_2702);\n    float _2722 = _2720.x;\n    bool _2725 = _2722 < _2609.x;\n    bool _2734;\n    if (!_2725)\n    {\n        _2734 = _2722 > _2609.z;\n    }\n    else\n    {\n        _2734 = _2725;\n    }\n    bool _2743;\n    if (!_2734)\n    {\n        _2743 = _2720.y < _2609.y;\n    }\n    else\n    {\n        _2743 = _2734;\n    }\n    bool _2752;\n    if (!_2743)\n    {\n        _2752 = _2720.y > _2609.w;\n    }\n    else\n    {\n        _2752 = _2743;\n    }\n    if (_2752)\n    {\n        return 1.0;\n    }\n    float _2758 = _2546.x;\n    float _2760;\n    if (_2758 > 0.0)\n    {\n        _2760 = _2758;\n    }\n    else\n    {\n        _2760 = 1.5 * _2626;\n    }\n    vec2 param_9 = _2720;\n    vec4 param_10 = _2609;\n    float param_11 = _2702 - (_2760 * (1.0 + (0.5 * _2673)));\n    float param_12 = _2626;\n    float param_13 = 1.0;\n    float param_14 = _2614.z * 0.25;\n    float param_15 = (_2626 * min(_2673, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2705, _2614.z);\n    int param_17 = int(_2541.z + 0.5);\n    float param_18 = _2541.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2063;\n    if (i == 0)\n    {\n        _2063 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2079;\n        if (i == 1)\n        {\n            _2079 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2087;\n            if (i == 2)\n            {\n                _2087 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2087 = fa_shadows[24].w;\n            }\n            _2079 = _2087;\n        }\n        _2063 = _2079;\n    }\n    return _2063;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2349 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2354 = clamp(dot(n, l), 0.0, 1.0);\n    float _2360 = sqrt(1.0 - (_2354 * _2354));\n    float _2367 = min(_2360 / max(_2354, 0.20000000298023223876953125), 4.0);\n    float _2372;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2372 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2372 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2397 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2372 * _2360)), 1.0);\n    float _2404 = _2397.x;\n    bool _2407 = _2404 < fa_shadows[ci * 1 + 16].x;\n    bool _2416;\n    if (!_2407)\n    {\n        _2416 = _2404 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2416 = _2407;\n    }\n    bool _2425;\n    if (!_2416)\n    {\n        _2425 = _2397.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2425 = _2416;\n    }\n    bool _2434;\n    if (!_2425)\n    {\n        _2434 = _2397.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2434 = _2425;\n    }\n    bool _2441;\n    if (!_2434)\n    {\n        _2441 = _2397.z > 1.0;\n    }\n    else\n    {\n        _2441 = _2434;\n    }\n    if (_2441)\n    {\n        return -1.0;\n    }\n    float _2449;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2449 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2449 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2397.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2397.z - ((_2449 * (1.0 + (0.5 * _2367))) / _2349);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2349;\n    float param_5 = _2349 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2367, 3.0)) * 0.5) / _2349;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2827 = int(fa_shadows[25].x + 0.5);\n    if (_2827 < 1)\n    {\n        return 1.0;\n    }\n    float _2842 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2827 - 1;\n    if (_2842 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2854 = _2827 > 1;\n    bool _2861;\n    if (_2854)\n    {\n        _2861 = _2842 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2861 = _2854;\n    }\n    if (_2861)\n    {\n        ci = 1;\n    }\n    bool _2865 = _2827 > 2;\n    bool _2872;\n    if (_2865)\n    {\n        _2872 = _2842 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2872 = _2865;\n    }\n    if (_2872)\n    {\n        ci = 2;\n    }\n    bool _2876 = _2827 > 3;\n    bool _2883;\n    if (_2876)\n    {\n        _2883 = _2842 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2883 = _2876;\n    }\n    if (_2883)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2827)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2909 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2909;\n        if (_2909 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2934;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2934 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2934 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2953 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2934, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2964 = clamp((_2842 - (fa_shadow_split_at(param_7) - _2953)) / _2953, 0.0, 1.0);\n        if (_2964 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2827)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2985 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2985;\n                if (_2985 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2964);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3434 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3441;\n    if (!_3434)\n    {\n        _3441 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3441 = _3434;\n    }\n    if (_3441)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3454 = fa_light_texel(param);\n    float _3455 = _3454.y;\n    float len = _3455;\n    if (_3455 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3467 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3477 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3467);\n    if (_3477 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3483 = len;\n    float _3486 = min(_3483, 0.89999997615814208984375 * dist);\n    len = _3486;\n    float _3492 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3467);\n    float _3497 = _3492 + (0.5 * _3486);\n    vec3 _3503 = world + (gn * _3492);\n    float _3505 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3570;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3521 = (float(k) + _3505) * 0.083333335816860198974609375;\n        vec3 _3529 = _3503 + (l * (_3521 * len));\n        vec4 _3535 = vec4(_3529, 1.0);\n        float _3541 = dot(fa_mesh_fs_params[28], _3535);\n        if (_3541 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3561 = vec2(dot(fa_mesh_fs_params[26], _3535), dot(fa_mesh_fs_params[27], _3535)) / vec2(_3541);\n        float _3565 = _3561.x * 0.5;\n        float _3566 = _3565 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3570 = (_3561.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3570 = 0.5 - (_3561.y * 0.5);\n        }\n        bool _3586 = _3566 < 0.0;\n        bool _3593;\n        if (!_3586)\n        {\n            _3593 = _3566 >= 1.0;\n        }\n        else\n        {\n            _3593 = _3586;\n        }\n        bool _3600;\n        if (!_3593)\n        {\n            _3600 = _3570 < 0.0;\n        }\n        else\n        {\n            _3600 = _3593;\n        }\n        bool _3607;\n        if (!_3600)\n        {\n            _3607 = _3570 >= 1.0;\n        }\n        else\n        {\n            _3607 = _3600;\n        }\n        if (_3607)\n        {\n            break;\n        }\n        vec4 _3626 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_3566, _3570) * fa_mesh_fs_params[24].zw), 0);\n        if (_3626.w < 0.5)\n        {\n            continue;\n        }\n        float _3645 = (dot(fa_mesh_fs_params[29].xyz, _3529) + fa_mesh_fs_params[29].w) - _3626.x;\n        if ((_3645 > _3492) && (_3645 < _3497))\n        {\n            occ = max(occ, (1.0 - (_3521 * _3521)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3566, 0.5 - _3565), min(_3570, 1.0 - _3570))));\n        }\n    }\n    return 1.0 - (occ * _3477);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _3748 = fa_baked_keep(param);\n    if (_3748 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3774 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _5487 = _3774.color;\n    float _5488 = _3774.attenuation;\n    float _5489 = _3774.shadow;\n    bool _3777 = _3774.type == 0;\n    if (_3777 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3774.direction;\n        float _3788 = fa_shadow_factor(param_5, param_6);\n        _5489 = _3788;\n        _5487 *= _3788;\n    }\n    else\n    {\n        bool _3799 = _3774.type != 0;\n        bool _3805;\n        if (_3799)\n        {\n            _3805 = _5488 > 0.0;\n        }\n        else\n        {\n            _3805 = _3799;\n        }\n        if (_3805)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3774.direction;\n            float _3824 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5489 = _3824;\n            _5487 *= _3824;\n        }\n    }\n    bool _3834 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3840;\n    if (_3834)\n    {\n        _3840 = _5488 > 0.0;\n    }\n    else\n    {\n        _3840 = _3834;\n    }\n    if (_3840)\n    {\n        float _3847;\n        if (_3777)\n        {\n            _3847 = 1000000000.0;\n        }\n        else\n        {\n            _3847 = _3774._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _3774.direction;\n        float param_18 = _3847;\n        float _3865 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5489 *= _3865;\n        _5487 *= _3865;\n    }\n    float _3878 = _5488;\n    float _3879 = _3878 * _3748;\n    _5488 = _3879;\n    vec3 _3883 = _5487;\n    vec3 _3884 = _3883 * _3748;\n    _5487 = _3884;\n    return LightSample(_3774.direction, _3884, _3879, _5489, _3774._distance, _3774.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3009 = int(fa_shadows[25].x + 0.5);\n    float _3019 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3024 = _3009 > 0;\n    bool _3033;\n    if (_3024)\n    {\n        int param = _3009 - 1;\n        _3033 = _3019 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3033 = _3024;\n    }\n    if (_3033)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3039 = _3009 > 1;\n        bool _3046;\n        if (_3039)\n        {\n            _3046 = _3019 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3046 = _3039;\n        }\n        if (_3046)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3052 = _3009 > 2;\n        bool _3059;\n        if (_3052)\n        {\n            _3059 = _3019 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3059 = _3052;\n        }\n        if (_3059)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3065 = _3009 > 3;\n        bool _3072;\n        if (_3065)\n        {\n            _3072 = _3019 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3072 = _3065;\n        }\n        if (_3072)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5308 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5308 = -_5308;\n    }\n    vec3 _4883 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5308, fa_world_tangent, fa_uv, fa_vertex_color, _4883, gl_FrontFacing);\n    Surface _4891 = fa_standard_surface(param_1);\n    vec3 _5339 = _4891.albedo;\n    float _5340 = _4891.alpha;\n    vec3 _5341 = _4891.normal;\n    float _5342 = _4891.metallic;\n    float _5343 = _4891.roughness;\n    float _5344 = _4891.occlusion;\n    vec3 _5345 = _4891.emission;\n    float _5346 = _4891.clearcoat;\n    float _5347 = _4891.clearcoat_roughness;\n    vec3 _5348 = _4891.sheen_color;\n    float _5349 = _4891.sheen_roughness;\n    float _5350 = _4891.anisotropy;\n    float _5351 = _4891.anisotropy_rotation;\n    float _5352 = _4891.specular;\n    float _5353 = _4891.ior;\n    vec3 _5354 = _4891.specular_color;\n    float _5355 = _4891.transmission;\n    float _5356 = _4891.thickness;\n    vec3 _5357 = _4891.attenuation_color;\n    float _5358 = _4891.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5308, fa_world_tangent, fa_uv, fa_vertex_color, _4883, gl_FrontFacing);\n    Surface param_3 = _4891;\n    surface(param_2, param_3);\n    _5339 = param_3.albedo;\n    _5340 = param_3.alpha;\n    _5341 = param_3.normal;\n    _5342 = param_3.metallic;\n    _5343 = param_3.roughness;\n    _5344 = param_3.occlusion;\n    _5345 = param_3.emission;\n    _5346 = param_3.clearcoat;\n    _5347 = param_3.clearcoat_roughness;\n    _5348 = param_3.sheen_color;\n    _5349 = param_3.sheen_roughness;\n    _5350 = param_3.anisotropy;\n    _5351 = param_3.anisotropy_rotation;\n    _5352 = param_3.specular;\n    _5353 = param_3.ior;\n    _5354 = param_3.specular_color;\n    _5355 = param_3.transmission;\n    _5356 = param_3.thickness;\n    _5357 = param_3.attenuation_color;\n    _5358 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5308;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5339 = param_6;\n    _5341 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5339;\n    }\n    else\n    {\n        vec3 _4930 = _5341;\n        vec3 _4931 = normalize(_4930);\n        _5341 = _4931;\n        vec3 param_8 = _4931;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _5339) * _5344;\n        int _4950 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4950; ln++)\n        {\n            int param_9 = ln;\n            int _4963 = fa_cl_light(param_9);\n            int param_10 = _4963;\n            if (fa_baked_keep(param_10) <= 0.0)\n            {\n                continue;\n            }\n            int param_11 = _4963;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _5308;\n            LightSample _4979 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _5308, fa_world_tangent, fa_uv, fa_vertex_color, _4883, gl_FrontFacing);\n            Surface param_15 = Surface(_5339, _5340, _5341, _5342, _5343, _5344, _5345, _5346, _5347, _5348, _5349, _5350, _5351, _5352, _5353, _5354, _5355, _5356, _5357, _5358);\n            LightSample param_16 = _4979;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _4994 = result;\n    vec3 _4995 = _4994 + _5345;\n    result = _4995;\n    vec3 param_17 = _4995;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _5004 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5011;\n    if (!_5004)\n    {\n        _5011 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5011 = _5004;\n    }\n    if (_5011)\n    {\n        vec3 _5020 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5026 = dot(_5020, fa_mesh_fs_params[9].xyz);\n        bool _5030 = fa_mesh_fs_params[9].w > 0.5;\n        float _5031;\n        if (_5030)\n        {\n            _5031 = _5026;\n        }\n        else\n        {\n            _5031 = length(_5020);\n        }\n        float _5043 = _5031 - fa_mesh_fs_params[8].x;\n        if (_5043 > 0.0)\n        {\n            float _5052 = fa_mesh_fs_params[7].w * _5043;\n            float tau = _5052 * _5052;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5068;\n                if (_5030)\n                {\n                    _5068 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5026);\n                }\n                else\n                {\n                    _5068 = fa_mesh_fs_params[0].y;\n                }\n                float _5089 = mix(_5068, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5031, 0.0, 1.0));\n                float _5093 = fa_world_pos.y - _5089;\n                float _5098 = _5089 - fa_mesh_fs_params[8].z;\n                float _5103 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5106 = _5098 <= 0.0;\n                bool _5107 = !_5106;\n                bool _5113;\n                if (_5107)\n                {\n                    _5113 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5113 = _5106;\n                }\n                float _5114;\n                if (_5113)\n                {\n                    _5114 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5114 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5098, 80.0));\n                }\n                bool _5141;\n                if (_5107)\n                {\n                    _5141 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5141 = _5106;\n                }\n                float _5142;\n                if (_5141)\n                {\n                    _5142 = fa_mesh_fs_params[8].y * _5098;\n                }\n                else\n                {\n                    _5142 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5098, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5167 = _5103 <= 0.0;\n                bool _5174;\n                if (!_5167)\n                {\n                    _5174 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5174 = _5167;\n                }\n                float _5175;\n                if (_5174)\n                {\n                    _5175 = fa_mesh_fs_params[8].y * _5103;\n                }\n                else\n                {\n                    _5175 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5103, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5202;\n                if (abs(_5093) < 0.001000000047497451305389404296875)\n                {\n                    _5202 = _5114;\n                }\n                else\n                {\n                    _5202 = (_5175 - _5142) / _5093;\n                }\n                tau += (_5043 * max(_5202, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5340);\n}\n\n",
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
            "inst_name": "_416",
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
            "inst_name": "_2073",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1344 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1351;\n    if (!_1344)\n    {\n        _1351 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1351 = _1344;\n    }\n    bool _1359;\n    if (!_1351)\n    {\n        _1359 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1359 = _1351;\n    }\n    bool _1366;\n    if (!_1359)\n    {\n        _1366 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1366 = _1359;\n    }\n    bool _1373;\n    if (!_1366)\n    {\n        _1373 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1373 = _1366;\n    }\n    if (_1373)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1383 = vec4(world_pos, 1.0);\n    float _1389 = dot(fa_mesh_fs_params[16], _1383);\n    if (!(_1389 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1411 = vec2(dot(fa_mesh_fs_params[14], _1383), dot(fa_mesh_fs_params[15], _1383)) / vec2(_1389);\n    int _1415 = int(fa_mesh_fs_params[18].x);\n    int _1419 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1419) + clamp(int(floor(((_1411.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1419 - 1)) * _1415)) + clamp(int(floor(((_1411.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1415 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1495 = fa_cluster_texel(param);\n    return ivec2(int(_1495.x), int(_1495.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3722 = fa_cluster_lookup(param);\n    fa_cl_slot = _3722.x;\n    fa_cl_local = _3722.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3927 = fa_linear_to_srgb(param);\n        c = _3927;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3935 = fa_srgb_to_linear(param_1);\n            c = _3935;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _298;\n    if (i.front_facing)\n    {\n        _298 = i.world_normal;\n    }\n    else\n    {\n        _298 = -i.world_normal;\n    }\n    vec3 _322 = normalize(i.world_tangent.xyz - (_298 * dot(_298, i.world_tangent.xyz)));\n    vec3 _349 = normalize(((_322 * m.x) + ((cross(_298, _322) * i.world_tangent.w) * m.y)) + (_298 * m.z));\n    vec3 _352;\n    if (i.front_facing)\n    {\n        _352 = _349;\n    }\n    else\n    {\n        _352 = -_349;\n    }\n    return _352;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3966 = fa_tex_fix(param_2, param_3);\n    vec4 _5670 = base_t;\n    _5670.x = _3966.x;\n    _5670.y = _3966.y;\n    _5670.z = _3966.z;\n    base_t = _5670;\n    vec4 _3980 = (_5670 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5507 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4012 = fa_tex_fix(param_6, param_7);\n        vec3 _4015 = (_4012 * 2.0) - vec3(1.0);\n        vec2 _4020 = _4015.xy * fa_mesh_fs_params[6].x;\n        vec3 _5678 = _4015;\n        _5678.x = _4020.x;\n        _5678.y = _4020.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5678;\n        _5507 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4048 = fa_tex_fix(param_12, param_13);\n    vec4 _5681 = mrt;\n    _5681.x = _4048.x;\n    _5681.y = _4048.y;\n    _5681.z = _4048.z;\n    mrt = _5681;\n    vec4 _4076 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4076.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4087 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4117 = fa_tex_fix(param_20, param_21);\n    float _5512 = fa_mesh_fs_params[20].x;\n    float _5513 = fa_mesh_fs_params[20].y;\n    float _5516 = fa_mesh_fs_params[20].z;\n    float _5515 = fa_mesh_fs_params[21].w;\n    float _5518 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5512 *= _4087.y;\n            _5513 *= _4087.z;\n            _5515 *= _4076.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5516 *= mrt.x;\n            _5518 *= mrt.w;\n        }\n    }\n    return Surface(_3980.xyz, _3980.w, _5507, clamp(fa_mesh_fs_params[5].x * _4048.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4048.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4087.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4117), _5512, _5513, fa_mesh_fs_params[21].xyz, _5515, _5516, fa_mesh_fs_params[20].w, _5518, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1575 = rect.zw - rect.xy;\n    vec2 _1579 = _1575 * atlas;\n    vec2 _1583 = ddx * _1579;\n    vec2 _1587 = ddy * _1579;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1575), clamp(0.5 * log2(max(max(dot(_1583, _1583), dot(_1587, _1587)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1620 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1627;\n    if (!_1620)\n    {\n        _1627 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1627 = _1620;\n    }\n    if (_1627)\n    {\n        return;\n    }\n    vec3 _1633 = dFdx(world_pos);\n    vec3 _1636 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1640 = fa_cluster_texel(param);\n    int _1644 = int(_1640.w);\n    if (_1644 < 1)\n    {\n        return;\n    }\n    int _1654 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1654;\n    vec4 _1658 = fa_light_texel(param_1);\n    vec2 _1661 = _1658.yz;\n    int _1665 = int(_1658.w);\n    int param_2 = _1654 + 1;\n    vec4 _1670 = fa_light_texel(param_2);\n    float _1671 = _1670.x;\n    int _1677 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1681 = int(_1640.z);\n    vec3 _1946;\n    for (int k = 0; k < _1644; k++)\n    {\n        int _1694 = _1681 + k;\n        int param_3 = _1665 + (_1694 >> 2);\n        int _1711 = (_1654 + 2) + (int(fa_light_texel(param_3)[_1694 & 3]) * 7);\n        int param_4 = _1711 + 6;\n        vec4 _1716 = fa_light_texel(param_4);\n        if (((int(_1716.w + 0.5) >> _1677) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1711;\n        vec4 _1731 = fa_light_texel(param_5);\n        int param_6 = _1711 + 1;\n        vec4 _1736 = fa_light_texel(param_6);\n        int param_7 = _1711 + 2;\n        vec4 _1741 = fa_light_texel(param_7);\n        vec3 _1744 = _1731.xyz;\n        float _1749 = dot(_1744, world_pos) + _1731.w;\n        vec3 _1751 = _1736.xyz;\n        float _1756 = dot(_1751, world_pos) + _1736.w;\n        vec3 _1758 = _1741.xyz;\n        float _1763 = dot(_1758, world_pos) + _1741.w;\n        bool _1768 = abs(_1749) > 0.5;\n        bool _1776;\n        if (!_1768)\n        {\n            _1776 = abs(_1756) > 0.5;\n        }\n        else\n        {\n            _1776 = _1768;\n        }\n        bool _1784;\n        if (!_1776)\n        {\n            _1784 = abs(_1763) > 0.5;\n        }\n        else\n        {\n            _1784 = _1776;\n        }\n        if (_1784)\n        {\n            continue;\n        }\n        float _1799 = clamp(dot(geo_normal, normalize(_1758)) * _1716.z, 0.0, 1.0);\n        if (_1799 <= 0.0)\n        {\n            continue;\n        }\n        float _1819 = (clamp((0.5 - abs(_1763)) * 10.0, 0.0, 1.0) * _1799) * _1716.x;\n        vec2 _1827 = vec2(_1749 + 0.5, 0.5 - _1756);\n        vec2 _1837 = vec2(dot(_1744, _1633), dot(_1751, _1633));\n        vec2 _1847 = vec2(dot(_1744, _1636), dot(_1751, _1636));\n        int param_8 = _1711 + 5;\n        vec4 _1852 = fa_light_texel(param_8);\n        int param_9 = _1711 + 3;\n        vec4 _1857 = fa_light_texel(param_9);\n        int param_10 = _1711 + 4;\n        vec4 _1862 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1852.xyz;\n        bool _1872 = _1857.z > _1857.x;\n        if (_1872)\n        {\n            vec4 param_11 = _1857;\n            vec2 param_12 = _1827;\n            vec2 param_13 = _1661;\n            vec2 param_14 = _1837;\n            vec2 param_15 = _1847;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1671 > 0.5) && (_1671 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1898 = fa_dc_to_linear(param_16);\n                vec4 _5595 = tx;\n                _5595.x = _1898.x;\n                _5595.y = _1898.y;\n                _5595.z = _1898.z;\n                tx = _5595;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1819 * tex_a) * _1852.w, 0.0, 1.0)));\n        if (_1862.z > _1862.x)\n        {\n            vec4 param_17 = _1862;\n            vec2 param_18 = _1827;\n            vec2 param_19 = _1661;\n            vec2 param_20 = _1837;\n            vec2 param_21 = _1847;\n            vec4 _1942 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1671 > 1.5)\n            {\n                vec3 param_22 = _1942.xyz;\n                vec3 _1952 = fa_dc_to_srgb(param_22);\n                _1946 = _1952;\n            }\n            else\n            {\n                _1946 = _1942.xyz;\n            }\n            vec3 _1961 = (_1946 * 2.0) - vec3(1.0);\n            vec2 _1966 = _1961.xy * _1716.y;\n            vec3 _1988 = (normalize(_1744) * _1966.x) + (normalize(_1751) * _1966.y);\n            vec3 _1991 = normalize(normal);\n            normal = normalize(mix(_1991, normalize((_1991 * max(_1961.z, 0.0500000007450580596923828125)) + (_1988 - (_1991 * dot(_1991, _1988)))), vec3(clamp(_1819 * (_1872 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3186 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3186;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3206 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3209 = _3206.x;\n    float _3211 = _3206.z;\n    vec2 e = vec2(_3209, _3211);\n    if (_3206.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3211)) * ((_3209 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3209)) * ((_3211 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _4231 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _4236 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _4241 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _4246 = fa_light_texel(param_3);\n    bool _4249 = _4246.z < 0.5;\n    bool _4257;\n    if (!_4249)\n    {\n        _4257 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _4257 = _4249;\n    }\n    if (_4257)\n    {\n        return vec3(0.0);\n    }\n    float _4264 = max(_4231.w, 9.9999997473787516355514526367188e-05);\n    vec3 _4267 = _4236.xyz;\n    vec3 _4271 = _4231.xyz;\n    vec3 _4275 = (fa_world_pos - _4271) / vec3(_4264);\n    vec3 _4284 = min(_4275 + vec3(0.5), (_4267 - vec3(0.5)) - _4275);\n    float _4293 = min(_4284.x, min(_4284.y, _4284.z));\n    if (!(_4293 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4308 = _4267 - vec3(1.0);\n    vec3 _4309 = clamp(_4275, vec3(0.0), _4308);\n    vec3 _4317 = min(floor(_4309), max(_4267 - vec3(2.0), vec3(0.0)));\n    vec3 _4321 = _4309 - _4317;\n    vec3 _4333 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _4264));\n    int _4338 = int(_4241.y + 0.5);\n    vec3 sh[9];\n    for (int k = 0; k < 9; k++)\n    {\n        sh[k] = vec3(0.0);\n    }\n    float wsum = 0.0;\n    int _4356 = int(_4246.w);\n    int _4357 = 8 + _4356;\n    int _4362 = 9 + _4356;\n    float _4389;\n    float _4402;\n    float _4416;\n    for (int k_1 = 0; k_1 < _4357; k_1++)\n    {\n        float _4375 = float(k_1 & 1);\n        float _4379 = float((k_1 >> 1) & 1);\n        float _4383 = float((k_1 >> 2) & 1);\n        if (_4375 > 0.5)\n        {\n            _4389 = _4321.x;\n        }\n        else\n        {\n            _4389 = 1.0 - _4321.x;\n        }\n        if (_4379 > 0.5)\n        {\n            _4402 = _4321.y;\n        }\n        else\n        {\n            _4402 = 1.0 - _4321.y;\n        }\n        if (_4383 > 0.5)\n        {\n            _4416 = _4321.z;\n        }\n        else\n        {\n            _4416 = 1.0 - _4321.z;\n        }\n        float _4426 = (_4389 * _4402) * _4416;\n        if (!(_4426 > 0.0))\n        {\n            continue;\n        }\n        vec3 _4439 = min(_4317 + vec3(_4375, _4379, _4383), _4308);\n        int _4459 = int(((_4241.x + _4439.x) + (_4236.x * (_4439.y + (_4236.y * _4439.z)))) + 0.5);\n        vec2 _4474 = vec2(float(_4459 % _4338) * 10.0, 1024.0 + (float(_4459 / _4338) * 11.0));\n        vec2 param_4 = _4474 + vec2(9.5, 10.5);\n        vec4 _4482 = fa_gi_fetch(param_4);\n        bool _4485 = _4482.y < 0.5;\n        bool _4494;\n        if (!_4485)\n        {\n            _4494 = _4482.x > _4246.y;\n        }\n        else\n        {\n            _4494 = _4485;\n        }\n        if (_4494)\n        {\n            continue;\n        }\n        vec3 _4506 = _4333 - (_4271 + (_4439 * _4264));\n        float _4509 = length(_4506);\n        vec3 _4515 = _4506 / vec3(max(_4509, 9.9999997473787516355514526367188e-05));\n        float _4525 = max(9.9999997473787516355514526367188e-05, (dot(-_4515, n) + 1.0) * 0.5);\n        float w = _4426 * (_4525 * _4525);\n        vec3 param_5 = _4515;\n        vec2 param_6 = (_4474 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _4544 = fa_gi_fetch(param_6);\n        float _4551 = _4509 / max(_4241.z, 9.9999997473787516355514526367188e-05);\n        float _4554 = _4544.x;\n        if (_4551 > _4554)\n        {\n            float _4567 = max(_4544.y - (_4554 * _4554), 0.0);\n            float _4572 = _4551 - _4554;\n            float _4581 = _4567 / max(_4567 + (_4572 * _4572), 9.9999999600419720025001879548654e-13);\n            w *= ((_4581 * _4581) * _4581);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        for (int c = 0; c < _4362; c++)\n        {\n            vec2 param_7 = _4474 + vec2(float(c) + 0.5, 10.5);\n            sh[c] += (fa_gi_fetch(param_7).xyz * w);\n        }\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    for (int c_1 = 0; c_1 < 9; c_1++)\n    {\n        sh[c_1] /= vec3(wsum);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_4293 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _4662;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _4662 = _4246.x;\n    }\n    else\n    {\n        _4662 = 1.0;\n    }\n    vec3 param_8[9] = sh;\n    vec3 param_9 = n;\n    return fa_sh_eval(param_8, param_9) * (_4241.w * _4662);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _4686 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _4691 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _4696 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _4696) && (k < 8); k++)\n    {\n        int param = _4691 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _4686;\n        vec3 _4721 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _4726 = param_3 * left;\n        acc += (_4721 * _4726);\n        left -= _4726;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3293 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3299 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3293 > 0.0005000000237487256526947021484375)\n    {\n        if (_3299)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3293;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3293;\n        }\n    }\n    bool _3352 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3352)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3383 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3383)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3299 || _3352) || _3383)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _4755 = fa_gi_light(param, param_1);\n        if (param_1 < 0.999000012874603271484375)\n        {\n            vec3 _4764;\n            if (param_1 > 0.0)\n            {\n                vec3 param_2 = n;\n                _4764 = _4755 + (fa_ambient_light(param_2) * param_1);\n            }\n            else\n            {\n                _4764 = _4755;\n            }\n            return _4764;\n        }\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param[9] = c;\n        vec3 param_1 = n;\n        vec3 _4826 = fa_sh_eval(param, param_1);\n        if (fa_mesh_fs_params[32].w >= 1.0)\n        {\n            return _4826;\n        }\n        vec3 param_2 = n;\n        return mix(fa_realtime_or_ambient(param_2), _4826, vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3692;\n    if (fa_lm.z > 0.5)\n    {\n        _3692 = 0.0;\n    }\n    else\n    {\n        _3692 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _3703 = _3692 < 1.0;\n    bool _3709;\n    if (_3703)\n    {\n        int param = li;\n        _3709 = fa_light_baked(param);\n    }\n    else\n    {\n        _3709 = _3703;\n    }\n    return _3709 ? _3692 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _594 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _607 = (c - (ru * hx)) - p;\n        vec3 _613 = ru * (2.0 * hx);\n        float _619 = max(dot(_613, _613), 9.9999999392252902907785028219223e-09);\n        float _623 = dot(_607, _613);\n        float t = clamp((-_623) / _619, 0.0, 1.0);\n        if (_594)\n        {\n            float _638 = dot(r, _613);\n            float _644 = _619 - (_638 * _638);\n            if (abs(_644) > (9.9999997473787516355514526367188e-06 * _619))\n            {\n                t = clamp(((dot(r, _607) * _638) - _623) / _644, 0.0, 1.0);\n            }\n        }\n        return (p + _607) + (_613 * t);\n    }\n    vec3 q = p;\n    float _676 = dot(r, axis);\n    bool _684;\n    if (_594)\n    {\n        _684 = abs(_676) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _684 = _594;\n    }\n    if (_684)\n    {\n        float _694 = dot(c - p, axis) / _676;\n        if (_694 > 0.0)\n        {\n            q = p + (r * _694);\n        }\n    }\n    vec3 _707 = q - c;\n    vec2 xy = vec2(dot(_707, ru), dot(_707, uu));\n    if (shape > 0.5)\n    {\n        float _722 = length(xy);\n        if (_722 > hx)\n        {\n            xy *= (hx / _722);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _514 = dot(d, right);\n    float _518 = dot(d, up);\n    float _529;\n    if (((_514 * _514) + (_518 * _518)) > 1.0000000133514319600180897396058e-10)\n    {\n        _529 = atan(_518, _514) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _529 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_529 - floor(_529)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _364 = abs(d);\n    float _366 = _364.x;\n    float _368 = _364.y;\n    bool _369 = _366 >= _368;\n    bool _377;\n    if (_369)\n    {\n        _377 = _366 >= _364.z;\n    }\n    else\n    {\n        _377 = _369;\n    }\n    int _378;\n    if (_377)\n    {\n        _378 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _393;\n        if (_368 >= _364.z)\n        {\n            _393 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _393 = (d.z > 0.0) ? 4 : 5;\n        }\n        _378 = _393;\n    }\n    return _378;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _760 = fa_light_base(param);\n    bool _764 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _760;\n    vec4 _768 = fa_light_texel(param_1);\n    int param_2 = _760 + 1;\n    vec4 _773 = fa_light_texel(param_2);\n    float _776 = _773.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _788 = _764 && (_776 > 2.5);\n    fa_light_is_area = _788;\n    bool _790 = _776 < 0.5;\n    vec3 l;\n    if (_790)\n    {\n        l = normalize(_768.xyz);\n        if (_764)\n        {\n            int param_3 = _760 + 6;\n            vec4 _804 = fa_light_texel(param_3);\n            if (_804.z > 0.5)\n            {\n                int param_4 = _760 + 4;\n                vec4 _814 = fa_light_texel(param_4);\n                int param_5 = _760 + 5;\n                vec4 _819 = fa_light_texel(param_5);\n                vec2 param_6 = _804.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _814.xyz) * _814.w, (-dot(world_pos, _819.xyz)) * _819.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _849 = _768.xyz;\n        vec3 _851 = _849 - world_pos;\n        vec3 to_light = _851;\n        float _854 = length(_851);\n        float reach = _854;\n        bool front = true;\n        if (_788)\n        {\n            int param_8 = _760 + 7;\n            reach = max(_854 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _760 + 4;\n            vec4 _878 = fa_light_texel(param_9);\n            int param_10 = _760 + 5;\n            vec4 _883 = fa_light_texel(param_10);\n            int param_11 = _760 + 6;\n            vec4 _888 = fa_light_texel(param_11);\n            float _889 = _888.w;\n            int param_12 = _760 + 2;\n            vec3 _896 = normalize(fa_light_texel(param_12).xyz);\n            bool _898 = _889 > 1.5;\n            bool _906;\n            if (!_898)\n            {\n                _906 = dot(_896, to_light) < 0.0;\n            }\n            else\n            {\n                _906 = _898;\n            }\n            front = _906;\n            vec3 r = vec3(0.0);\n            vec3 _915 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _919 = dot(n, n) > 0.5;\n            bool _927;\n            if (_919)\n            {\n                _927 = dot(_915, _915) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _927 = _919;\n            }\n            if (_927)\n            {\n                r = reflect(-normalize(_915), normalize(n));\n            }\n            vec3 param_13 = _849;\n            vec3 param_14 = _896;\n            vec3 param_15 = _878.xyz;\n            vec3 param_16 = _883.xyz;\n            float param_17 = _878.w;\n            float param_18 = _883.w;\n            float param_19 = _889;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _963 = length(to_light);\n        dist = _963;\n        l = to_light / vec3(max(_963, 9.9999997473787516355514526367188e-05));\n        float _977 = reach / max(_768.w, 0.001000000047497451305389404296875);\n        float _983 = clamp(1.0 - (_977 * _977), 0.0, 1.0);\n        float _985;\n        if (front)\n        {\n            _985 = _983 * _983;\n        }\n        else\n        {\n            _985 = 0.0;\n        }\n        atten = _985;\n        bool _996 = _776 < 2.5;\n        if ((_776 > 1.5) && _996)\n        {\n            int param_22 = _760 + 2;\n            vec4 _1004 = fa_light_texel(param_22);\n            float _1014 = _1004.w;\n            int param_23 = _760 + 3;\n            vec4 _1019 = fa_light_texel(param_23);\n            float _1020 = _1019.x;\n            float cos_inner = _1020;\n            if (_1020 > 1.5)\n            {\n                cos_inner = mix(_1014, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1014, cos_inner, dot(-l, normalize(_1004.xyz)));\n        }\n        if (_764 && (_776 < 1.5))\n        {\n            int param_24 = _760 + 6;\n            vec4 _1044 = fa_light_texel(param_24);\n            if (_1044.z > 0.5)\n            {\n                vec3 _1052 = -to_light;\n                int param_25 = _760 + 4;\n                int param_26 = _760 + 5;\n                vec3 _1066 = fa_light_texel(param_25).xyz;\n                vec3 _1070 = fa_light_texel(param_26).xyz;\n                vec3 _1079 = vec3(dot(_1052, _1066), dot(_1052, _1070), dot(_1052, cross(_1066, _1070)));\n                vec3 param_27 = _1079;\n                int _1083 = fa_cube_face(param_27);\n                int param_28 = _1083;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1110 = vec2(dot(_1079, cross(param_29, param_30)), dot(_1079, param_30)) / vec2(max(dot(_1079, param_29), 9.9999997473787516355514526367188e-05));\n                int _1114 = _1083 / 3;\n                vec2 param_31 = _1044.xy + (vec2(float(_1083 - (_1114 * 3)), float(_1114)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1110.x), 0.5 - (0.5 * _1110.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _760 + 7;\n            vec4 _1144 = fa_light_texel(param_33);\n            if (_1144.z > 0.5)\n            {\n                int param_34 = _760 + 2;\n                int param_35 = _760 + 4;\n                int param_36 = _760 + 5;\n                vec2 param_37 = _1144.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_764 && _996)\n            {\n                int param_42 = _760 + 6;\n                vec4 _1191 = fa_light_texel(param_42);\n                int param_43 = _760 + 7;\n                vec4 _1196 = fa_light_texel(param_43);\n                bool _1199 = _1191.z > 0.5;\n                bool _1206;\n                if (!_1199)\n                {\n                    _1206 = _1196.z > 0.5;\n                }\n                else\n                {\n                    _1206 = _1199;\n                }\n                if (_1206)\n                {\n                    int param_44 = _760 + 2;\n                    vec4 _1213 = fa_light_texel(param_44);\n                    vec3 _1217 = normalize(_1213.xyz);\n                    int param_45 = _760 + 4;\n                    vec4 _1222 = fa_light_texel(param_45);\n                    int param_46 = _760 + 5;\n                    vec4 _1227 = fa_light_texel(param_46);\n                    if (_1199)\n                    {\n                        vec3 _1235 = -to_light;\n                        float _1242 = _1213.w;\n                        float _1258 = 0.5 / max(dot(_1235, _1217) * (sqrt(max(1.0 - (_1242 * _1242), 0.0)) / max(_1242, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1191.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1235, _1222.xyz) * _1258), 0.5 - (dot(_1235, _1227.xyz) * _1258));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1196.z > 0.5)\n                    {\n                        vec2 param_49 = _1196.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1217;\n                        vec3 param_52 = _1222.xyz;\n                        vec3 param_53 = _1227.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5461 = _773.xyz * atten;\n    if (_764)\n    {\n        _5461 *= fa_light_tint;\n    }\n    int _1326;\n    if (_790)\n    {\n        _1326 = 0;\n    }\n    else\n    {\n        _1326 = ((_776 > 1.5) && (_776 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5461, atten, 1.0, dist, _1326);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2120 = fa_shadow_depth(param, param_1);\n    float _2124;\n    if (conv.x < 0.5)\n    {\n        _2124 = _2120;\n    }\n    else\n    {\n        _2124 = (conv.y * conv.z) / (conv.z - (_2120 * (conv.z - conv.y)));\n    }\n    return _2124;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2051 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2051), sin(_2051)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2170 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2179;\n        if (k < 0.0)\n        {\n            _2179 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2179 = k;\n        }\n        float _2199 = clamp((_2179 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2170;\n            vec2 _2218 = fa_shadow_vogel(param_3, param_4, param_5) * _2199;\n            vec2 param_6 = uv + (_2218 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2230 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2230 < (zr - (length(_2218) * plane)))\n            {\n                sum += _2230;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2256 = sum / cnt;\n        float _2266;\n        if (k < 0.0)\n        {\n            _2266 = (-k) / max(_2256, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2266 = k;\n        }\n        radius = clamp(((max(zr - _2256, 0.0) * unit) * _2266) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2288 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2288; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2288;\n        float param_11 = _2170;\n        vec2 _2307 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2307 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2307) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2288);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2507 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2514;\n    if (!_2507)\n    {\n        _2514 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2514 = _2507;\n    }\n    if (_2514)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2527 = fa_light_texel(param);\n    float _2528 = _2527.x;\n    if (_2528 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2537 = int(_2528 + 0.5);\n    int param_1 = _2537;\n    vec4 _2541 = fa_light_texel(param_1);\n    int param_2 = _2537 + 1;\n    vec4 _2546 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2549 = _2541.y;\n    if (_2549 > 0.0)\n    {\n        float _2566 = 1.0 - smoothstep(0.75 * _2549, _2549, length(world - fa_shadows[27].xyz));\n        fade = _2566;\n        if (_2566 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2541.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2590 = (_2537 + 2) + (face * 6);\n    int param_4 = _2590;\n    int param_5 = _2590 + 1;\n    int param_6 = _2590 + 3;\n    vec4 _2604 = fa_light_texel(param_6);\n    int param_7 = _2590 + 4;\n    vec4 _2609 = fa_light_texel(param_7);\n    int param_8 = _2590 + 5;\n    vec4 _2614 = fa_light_texel(param_8);\n    float _2626 = _2614.x * max(dot(_2604, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2631 = clamp(dot(n, l), 0.0, 1.0);\n    float _2654 = clamp(dot(n, _2604.xyz), -1.0, 1.0);\n    float _2673 = min(sqrt(1.0 - (_2654 * _2654)) / max(abs(dot(n, world - lpos)) / max(dot(_2604, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2676 = _2546.y;\n    float _2678;\n    if (_2676 > 0.0)\n    {\n        _2678 = _2676;\n    }\n    else\n    {\n        _2678 = 1.5 * _2626;\n    }\n    vec4 _2698 = vec4(world + (n * (_2678 * sqrt(1.0 - (_2631 * _2631)))), 1.0);\n    float _2702 = dot(_2604, _2698);\n    float _2705 = _2614.y;\n    if (_2702 < _2705)\n    {\n        return 1.0;\n    }\n    vec2 _2720 = vec2(dot(fa_light_texel(param_4), _2698), dot(fa_light_texel(param_5), _2698)) / vec2(_2702);\n    float _2722 = _2720.x;\n    bool _2725 = _2722 < _2609.x;\n    bool _2734;\n    if (!_2725)\n    {\n        _2734 = _2722 > _2609.z;\n    }\n    else\n    {\n        _2734 = _2725;\n    }\n    bool _2743;\n    if (!_2734)\n    {\n        _2743 = _2720.y < _2609.y;\n    }\n    else\n    {\n        _2743 = _2734;\n    }\n    bool _2752;\n    if (!_2743)\n    {\n        _2752 = _2720.y > _2609.w;\n    }\n    else\n    {\n        _2752 = _2743;\n    }\n    if (_2752)\n    {\n        return 1.0;\n    }\n    float _2758 = _2546.x;\n    float _2760;\n    if (_2758 > 0.0)\n    {\n        _2760 = _2758;\n    }\n    else\n    {\n        _2760 = 1.5 * _2626;\n    }\n    vec2 param_9 = _2720;\n    vec4 param_10 = _2609;\n    float param_11 = _2702 - (_2760 * (1.0 + (0.5 * _2673)));\n    float param_12 = _2626;\n    float param_13 = 1.0;\n    float param_14 = _2614.z * 0.25;\n    float param_15 = (_2626 * min(_2673, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2705, _2614.z);\n    int param_17 = int(_2541.z + 0.5);\n    float param_18 = _2541.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2063;\n    if (i == 0)\n    {\n        _2063 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2079;\n        if (i == 1)\n        {\n            _2079 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2087;\n            if (i == 2)\n            {\n                _2087 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2087 = fa_shadows[24].w;\n            }\n            _2079 = _2087;\n        }\n        _2063 = _2079;\n    }\n    return _2063;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2349 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2354 = clamp(dot(n, l), 0.0, 1.0);\n    float _2360 = sqrt(1.0 - (_2354 * _2354));\n    float _2367 = min(_2360 / max(_2354, 0.20000000298023223876953125), 4.0);\n    float _2372;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2372 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2372 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2397 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2372 * _2360)), 1.0);\n    float _2404 = _2397.x;\n    bool _2407 = _2404 < fa_shadows[ci * 1 + 16].x;\n    bool _2416;\n    if (!_2407)\n    {\n        _2416 = _2404 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2416 = _2407;\n    }\n    bool _2425;\n    if (!_2416)\n    {\n        _2425 = _2397.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2425 = _2416;\n    }\n    bool _2434;\n    if (!_2425)\n    {\n        _2434 = _2397.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2434 = _2425;\n    }\n    bool _2441;\n    if (!_2434)\n    {\n        _2441 = _2397.z > 1.0;\n    }\n    else\n    {\n        _2441 = _2434;\n    }\n    if (_2441)\n    {\n        return -1.0;\n    }\n    float _2449;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2449 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2449 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2397.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2397.z - ((_2449 * (1.0 + (0.5 * _2367))) / _2349);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2349;\n    float param_5 = _2349 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2367, 3.0)) * 0.5) / _2349;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2827 = int(fa_shadows[25].x + 0.5);\n    if (_2827 < 1)\n    {\n        return 1.0;\n    }\n    float _2842 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2827 - 1;\n    if (_2842 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2854 = _2827 > 1;\n    bool _2861;\n    if (_2854)\n    {\n        _2861 = _2842 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2861 = _2854;\n    }\n    if (_2861)\n    {\n        ci = 1;\n    }\n    bool _2865 = _2827 > 2;\n    bool _2872;\n    if (_2865)\n    {\n        _2872 = _2842 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2872 = _2865;\n    }\n    if (_2872)\n    {\n        ci = 2;\n    }\n    bool _2876 = _2827 > 3;\n    bool _2883;\n    if (_2876)\n    {\n        _2883 = _2842 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2883 = _2876;\n    }\n    if (_2883)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2827)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2909 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2909;\n        if (_2909 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2934;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2934 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2934 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2953 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2934, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2964 = clamp((_2842 - (fa_shadow_split_at(param_7) - _2953)) / _2953, 0.0, 1.0);\n        if (_2964 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2827)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2985 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2985;\n                if (_2985 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2964);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3434 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3441;\n    if (!_3434)\n    {\n        _3441 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3441 = _3434;\n    }\n    if (_3441)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3454 = fa_light_texel(param);\n    float _3455 = _3454.y;\n    float len = _3455;\n    if (_3455 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3467 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3477 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3467);\n    if (_3477 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3483 = len;\n    float _3486 = min(_3483, 0.89999997615814208984375 * dist);\n    len = _3486;\n    float _3492 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3467);\n    float _3497 = _3492 + (0.5 * _3486);\n    vec3 _3503 = world + (gn * _3492);\n    float _3505 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3570;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3521 = (float(k) + _3505) * 0.083333335816860198974609375;\n        vec3 _3529 = _3503 + (l * (_3521 * len));\n        vec4 _3535 = vec4(_3529, 1.0);\n        float _3541 = dot(fa_mesh_fs_params[28], _3535);\n        if (_3541 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3561 = vec2(dot(fa_mesh_fs_params[26], _3535), dot(fa_mesh_fs_params[27], _3535)) / vec2(_3541);\n        float _3565 = _3561.x * 0.5;\n        float _3566 = _3565 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3570 = (_3561.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3570 = 0.5 - (_3561.y * 0.5);\n        }\n        bool _3586 = _3566 < 0.0;\n        bool _3593;\n        if (!_3586)\n        {\n            _3593 = _3566 >= 1.0;\n        }\n        else\n        {\n            _3593 = _3586;\n        }\n        bool _3600;\n        if (!_3593)\n        {\n            _3600 = _3570 < 0.0;\n        }\n        else\n        {\n            _3600 = _3593;\n        }\n        bool _3607;\n        if (!_3600)\n        {\n            _3607 = _3570 >= 1.0;\n        }\n        else\n        {\n            _3607 = _3600;\n        }\n        if (_3607)\n        {\n            break;\n        }\n        vec4 _3626 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_3566, _3570) * fa_mesh_fs_params[24].zw), 0);\n        if (_3626.w < 0.5)\n        {\n            continue;\n        }\n        float _3645 = (dot(fa_mesh_fs_params[29].xyz, _3529) + fa_mesh_fs_params[29].w) - _3626.x;\n        if ((_3645 > _3492) && (_3645 < _3497))\n        {\n            occ = max(occ, (1.0 - (_3521 * _3521)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3566, 0.5 - _3565), min(_3570, 1.0 - _3570))));\n        }\n    }\n    return 1.0 - (occ * _3477);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _3748 = fa_baked_keep(param);\n    if (_3748 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3774 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _5487 = _3774.color;\n    float _5488 = _3774.attenuation;\n    float _5489 = _3774.shadow;\n    bool _3777 = _3774.type == 0;\n    if (_3777 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3774.direction;\n        float _3788 = fa_shadow_factor(param_5, param_6);\n        _5489 = _3788;\n        _5487 *= _3788;\n    }\n    else\n    {\n        bool _3799 = _3774.type != 0;\n        bool _3805;\n        if (_3799)\n        {\n            _3805 = _5488 > 0.0;\n        }\n        else\n        {\n            _3805 = _3799;\n        }\n        if (_3805)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3774.direction;\n            float _3824 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5489 = _3824;\n            _5487 *= _3824;\n        }\n    }\n    bool _3834 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3840;\n    if (_3834)\n    {\n        _3840 = _5488 > 0.0;\n    }\n    else\n    {\n        _3840 = _3834;\n    }\n    if (_3840)\n    {\n        float _3847;\n        if (_3777)\n        {\n            _3847 = 1000000000.0;\n        }\n        else\n        {\n            _3847 = _3774._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _3774.direction;\n        float param_18 = _3847;\n        float _3865 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5489 *= _3865;\n        _5487 *= _3865;\n    }\n    float _3878 = _5488;\n    float _3879 = _3878 * _3748;\n    _5488 = _3879;\n    vec3 _3883 = _5487;\n    vec3 _3884 = _3883 * _3748;\n    _5487 = _3884;\n    return LightSample(_3774.direction, _3884, _3879, _5489, _3774._distance, _3774.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3009 = int(fa_shadows[25].x + 0.5);\n    float _3019 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3024 = _3009 > 0;\n    bool _3033;\n    if (_3024)\n    {\n        int param = _3009 - 1;\n        _3033 = _3019 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3033 = _3024;\n    }\n    if (_3033)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3039 = _3009 > 1;\n        bool _3046;\n        if (_3039)\n        {\n            _3046 = _3019 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3046 = _3039;\n        }\n        if (_3046)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3052 = _3009 > 2;\n        bool _3059;\n        if (_3052)\n        {\n            _3059 = _3019 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3059 = _3052;\n        }\n        if (_3059)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3065 = _3009 > 3;\n        bool _3072;\n        if (_3065)\n        {\n            _3072 = _3019 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3072 = _3065;\n        }\n        if (_3072)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5308 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5308 = -_5308;\n    }\n    vec3 _4883 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5308, fa_world_tangent, fa_uv, fa_vertex_color, _4883, gl_FrontFacing);\n    Surface _4891 = fa_standard_surface(param_1);\n    vec3 _5339 = _4891.albedo;\n    float _5340 = _4891.alpha;\n    vec3 _5341 = _4891.normal;\n    float _5342 = _4891.metallic;\n    float _5343 = _4891.roughness;\n    float _5344 = _4891.occlusion;\n    vec3 _5345 = _4891.emission;\n    float _5346 = _4891.clearcoat;\n    float _5347 = _4891.clearcoat_roughness;\n    vec3 _5348 = _4891.sheen_color;\n    float _5349 = _4891.sheen_roughness;\n    float _5350 = _4891.anisotropy;\n    float _5351 = _4891.anisotropy_rotation;\n    float _5352 = _4891.specular;\n    float _5353 = _4891.ior;\n    vec3 _5354 = _4891.specular_color;\n    float _5355 = _4891.transmission;\n    float _5356 = _4891.thickness;\n    vec3 _5357 = _4891.attenuation_color;\n    float _5358 = _4891.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5308, fa_world_tangent, fa_uv, fa_vertex_color, _4883, gl_FrontFacing);\n    Surface param_3 = _4891;\n    surface(param_2, param_3);\n    _5339 = param_3.albedo;\n    _5340 = param_3.alpha;\n    _5341 = param_3.normal;\n    _5342 = param_3.metallic;\n    _5343 = param_3.roughness;\n    _5344 = param_3.occlusion;\n    _5345 = param_3.emission;\n    _5346 = param_3.clearcoat;\n    _5347 = param_3.clearcoat_roughness;\n    _5348 = param_3.sheen_color;\n    _5349 = param_3.sheen_roughness;\n    _5350 = param_3.anisotropy;\n    _5351 = param_3.anisotropy_rotation;\n    _5352 = param_3.specular;\n    _5353 = param_3.ior;\n    _5354 = param_3.specular_color;\n    _5355 = param_3.transmission;\n    _5356 = param_3.thickness;\n    _5357 = param_3.attenuation_color;\n    _5358 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5308;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5339 = param_6;\n    _5341 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5339;\n    }\n    else\n    {\n        vec3 _4930 = _5341;\n        vec3 _4931 = normalize(_4930);\n        _5341 = _4931;\n        vec3 param_8 = _4931;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _5339) * _5344;\n        int _4950 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4950; ln++)\n        {\n            int param_9 = ln;\n            int _4963 = fa_cl_light(param_9);\n            int param_10 = _4963;\n            if (fa_baked_keep(param_10) <= 0.0)\n            {\n                continue;\n            }\n            int param_11 = _4963;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _5308;\n            LightSample _4979 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _5308, fa_world_tangent, fa_uv, fa_vertex_color, _4883, gl_FrontFacing);\n            Surface param_15 = Surface(_5339, _5340, _5341, _5342, _5343, _5344, _5345, _5346, _5347, _5348, _5349, _5350, _5351, _5352, _5353, _5354, _5355, _5356, _5357, _5358);\n            LightSample param_16 = _4979;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _4994 = result;\n    vec3 _4995 = _4994 + _5345;\n    result = _4995;\n    vec3 param_17 = _4995;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _5004 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5011;\n    if (!_5004)\n    {\n        _5011 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5011 = _5004;\n    }\n    if (_5011)\n    {\n        vec3 _5020 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5026 = dot(_5020, fa_mesh_fs_params[9].xyz);\n        bool _5030 = fa_mesh_fs_params[9].w > 0.5;\n        float _5031;\n        if (_5030)\n        {\n            _5031 = _5026;\n        }\n        else\n        {\n            _5031 = length(_5020);\n        }\n        float _5043 = _5031 - fa_mesh_fs_params[8].x;\n        if (_5043 > 0.0)\n        {\n            float _5052 = fa_mesh_fs_params[7].w * _5043;\n            float tau = _5052 * _5052;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5068;\n                if (_5030)\n                {\n                    _5068 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5026);\n                }\n                else\n                {\n                    _5068 = fa_mesh_fs_params[0].y;\n                }\n                float _5089 = mix(_5068, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5031, 0.0, 1.0));\n                float _5093 = fa_world_pos.y - _5089;\n                float _5098 = _5089 - fa_mesh_fs_params[8].z;\n                float _5103 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5106 = _5098 <= 0.0;\n                bool _5107 = !_5106;\n                bool _5113;\n                if (_5107)\n                {\n                    _5113 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5113 = _5106;\n                }\n                float _5114;\n                if (_5113)\n                {\n                    _5114 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5114 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5098, 80.0));\n                }\n                bool _5141;\n                if (_5107)\n                {\n                    _5141 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5141 = _5106;\n                }\n                float _5142;\n                if (_5141)\n                {\n                    _5142 = fa_mesh_fs_params[8].y * _5098;\n                }\n                else\n                {\n                    _5142 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5098, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5167 = _5103 <= 0.0;\n                bool _5174;\n                if (!_5167)\n                {\n                    _5174 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5174 = _5167;\n                }\n                float _5175;\n                if (_5174)\n                {\n                    _5175 = fa_mesh_fs_params[8].y * _5103;\n                }\n                else\n                {\n                    _5175 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5103, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5202;\n                if (abs(_5093) < 0.001000000047497451305389404296875)\n                {\n                    _5202 = _5114;\n                }\n                else\n                {\n                    _5202 = (_5175 - _5142) / _5093;\n                }\n                tau += (_5043 * max(_5202, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5340);\n}\n\n",
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
            "inst_name": "_416",
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
            "inst_name": "_2073",
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
