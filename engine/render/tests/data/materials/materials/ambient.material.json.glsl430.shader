{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "21384afe6cb0557eed79a6c482a811939939d99108959ca6157b877697a348a6",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[39];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1324 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1331;\n    if (!_1324)\n    {\n        _1331 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1331 = _1324;\n    }\n    bool _1339;\n    if (!_1331)\n    {\n        _1339 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1339 = _1331;\n    }\n    bool _1346;\n    if (!_1339)\n    {\n        _1346 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1346 = _1339;\n    }\n    bool _1353;\n    if (!_1346)\n    {\n        _1353 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1353 = _1346;\n    }\n    if (_1353)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1363 = vec4(world_pos, 1.0);\n    float _1369 = dot(fa_mesh_fs_params[16], _1363);\n    if (!(_1369 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1391 = vec2(dot(fa_mesh_fs_params[14], _1363), dot(fa_mesh_fs_params[15], _1363)) / vec2(_1369);\n    int _1395 = int(fa_mesh_fs_params[18].x);\n    int _1399 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1399) + clamp(int(floor(((_1391.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1399 - 1)) * _1395)) + clamp(int(floor(((_1391.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1395 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1475 = fa_cluster_texel(param);\n    return ivec2(int(_1475.x), int(_1475.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3534 = fa_cluster_lookup(param);\n    fa_cl_slot = _3534.x;\n    fa_cl_local = _3534.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3744 = fa_linear_to_srgb(param);\n        c = _3744;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3752 = fa_srgb_to_linear(param_1);\n            c = _3752;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _278;\n    if (i.front_facing)\n    {\n        _278 = i.world_normal;\n    }\n    else\n    {\n        _278 = -i.world_normal;\n    }\n    vec3 _302 = normalize(i.world_tangent.xyz - (_278 * dot(_278, i.world_tangent.xyz)));\n    vec3 _329 = normalize(((_302 * m.x) + ((cross(_278, _302) * i.world_tangent.w) * m.y)) + (_278 * m.z));\n    vec3 _332;\n    if (i.front_facing)\n    {\n        _332 = _329;\n    }\n    else\n    {\n        _332 = -_329;\n    }\n    return _332;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3783 = fa_tex_fix(param_2, param_3);\n    vec4 _4874 = base_t;\n    _4874.x = _3783.x;\n    _4874.y = _3783.y;\n    _4874.z = _3783.z;\n    base_t = _4874;\n    vec4 _3797 = (_4874 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4726 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3829 = fa_tex_fix(param_6, param_7);\n        vec3 _3832 = (_3829 * 2.0) - vec3(1.0);\n        vec2 _3837 = _3832.xy * fa_mesh_fs_params[6].x;\n        vec3 _4882 = _3832;\n        _4882.x = _3837.x;\n        _4882.y = _3837.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4882;\n        _4726 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3865 = fa_tex_fix(param_12, param_13);\n    vec4 _4885 = mrt;\n    _4885.x = _3865.x;\n    _4885.y = _3865.y;\n    _4885.z = _3865.z;\n    mrt = _4885;\n    vec4 _3893 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3893.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3904 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3934 = fa_tex_fix(param_20, param_21);\n    float _4731 = fa_mesh_fs_params[20].x;\n    float _4732 = fa_mesh_fs_params[20].y;\n    float _4735 = fa_mesh_fs_params[20].z;\n    float _4734 = fa_mesh_fs_params[21].w;\n    float _4737 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4731 *= _3904.y;\n            _4732 *= _3904.z;\n            _4734 *= _3893.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4735 *= mrt.x;\n            _4737 *= mrt.w;\n        }\n    }\n    return Surface(_3797.xyz, _3797.w, _4726, clamp(fa_mesh_fs_params[5].x * _3865.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3865.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3904.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3934), _4731, _4732, fa_mesh_fs_params[21].xyz, _4734, _4735, fa_mesh_fs_params[20].w, _4737, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1555 = rect.zw - rect.xy;\n    vec2 _1559 = _1555 * atlas;\n    vec2 _1563 = ddx * _1559;\n    vec2 _1567 = ddy * _1559;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1555), clamp(0.5 * log2(max(max(dot(_1563, _1563), dot(_1567, _1567)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1600 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1607;\n    if (!_1600)\n    {\n        _1607 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1607 = _1600;\n    }\n    if (_1607)\n    {\n        return;\n    }\n    vec3 _1613 = dFdx(world_pos);\n    vec3 _1616 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1620 = fa_cluster_texel(param);\n    int _1624 = int(_1620.w);\n    if (_1624 < 1)\n    {\n        return;\n    }\n    int _1634 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1634;\n    vec4 _1638 = fa_light_texel(param_1);\n    vec2 _1641 = _1638.yz;\n    int _1645 = int(_1638.w);\n    int param_2 = _1634 + 1;\n    vec4 _1650 = fa_light_texel(param_2);\n    float _1651 = _1650.x;\n    int _1657 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1661 = int(_1620.z);\n    vec3 _1926;\n    for (int k = 0; k < _1624; k++)\n    {\n        int _1674 = _1661 + k;\n        int param_3 = _1645 + (_1674 >> 2);\n        int _1691 = (_1634 + 2) + (int(fa_light_texel(param_3)[_1674 & 3]) * 7);\n        int param_4 = _1691 + 6;\n        vec4 _1696 = fa_light_texel(param_4);\n        if (((int(_1696.w + 0.5) >> _1657) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1691;\n        vec4 _1711 = fa_light_texel(param_5);\n        int param_6 = _1691 + 1;\n        vec4 _1716 = fa_light_texel(param_6);\n        int param_7 = _1691 + 2;\n        vec4 _1721 = fa_light_texel(param_7);\n        vec3 _1724 = _1711.xyz;\n        float _1729 = dot(_1724, world_pos) + _1711.w;\n        vec3 _1731 = _1716.xyz;\n        float _1736 = dot(_1731, world_pos) + _1716.w;\n        vec3 _1738 = _1721.xyz;\n        float _1743 = dot(_1738, world_pos) + _1721.w;\n        bool _1748 = abs(_1729) > 0.5;\n        bool _1756;\n        if (!_1748)\n        {\n            _1756 = abs(_1736) > 0.5;\n        }\n        else\n        {\n            _1756 = _1748;\n        }\n        bool _1764;\n        if (!_1756)\n        {\n            _1764 = abs(_1743) > 0.5;\n        }\n        else\n        {\n            _1764 = _1756;\n        }\n        if (_1764)\n        {\n            continue;\n        }\n        float _1779 = clamp(dot(geo_normal, normalize(_1738)) * _1696.z, 0.0, 1.0);\n        if (_1779 <= 0.0)\n        {\n            continue;\n        }\n        float _1799 = (clamp((0.5 - abs(_1743)) * 10.0, 0.0, 1.0) * _1779) * _1696.x;\n        vec2 _1807 = vec2(_1729 + 0.5, 0.5 - _1736);\n        vec2 _1817 = vec2(dot(_1724, _1613), dot(_1731, _1613));\n        vec2 _1827 = vec2(dot(_1724, _1616), dot(_1731, _1616));\n        int param_8 = _1691 + 5;\n        vec4 _1832 = fa_light_texel(param_8);\n        int param_9 = _1691 + 3;\n        vec4 _1837 = fa_light_texel(param_9);\n        int param_10 = _1691 + 4;\n        vec4 _1842 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1832.xyz;\n        bool _1852 = _1837.z > _1837.x;\n        if (_1852)\n        {\n            vec4 param_11 = _1837;\n            vec2 param_12 = _1807;\n            vec2 param_13 = _1641;\n            vec2 param_14 = _1817;\n            vec2 param_15 = _1827;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1651 > 0.5) && (_1651 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1878 = fa_dc_to_linear(param_16);\n                vec4 _4806 = tx;\n                _4806.x = _1878.x;\n                _4806.y = _1878.y;\n                _4806.z = _1878.z;\n                tx = _4806;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1799 * tex_a) * _1832.w, 0.0, 1.0)));\n        if (_1842.z > _1842.x)\n        {\n            vec4 param_17 = _1842;\n            vec2 param_18 = _1807;\n            vec2 param_19 = _1641;\n            vec2 param_20 = _1817;\n            vec2 param_21 = _1827;\n            vec4 _1922 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1651 > 1.5)\n            {\n                vec3 param_22 = _1922.xyz;\n                vec3 _1932 = fa_dc_to_srgb(param_22);\n                _1926 = _1932;\n            }\n            else\n            {\n                _1926 = _1922.xyz;\n            }\n            vec3 _1941 = (_1926 * 2.0) - vec3(1.0);\n            vec2 _1946 = _1941.xy * _1696.y;\n            vec3 _1968 = (normalize(_1724) * _1946.x) + (normalize(_1731) * _1946.y);\n            vec3 _1971 = normalize(normal);\n            normal = normalize(mix(_1971, normalize((_1971 * max(_1941.z, 0.0500000007450580596923828125)) + (_1968 - (_1971 * dot(_1971, _1968)))), vec3(clamp(_1799 * (_1852 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3166 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3166;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[30].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 30].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[30].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3504;\n    if (fa_lm.z > 0.5)\n    {\n        _3504 = 0.0;\n    }\n    else\n    {\n        _3504 = 1.0 - clamp(fa_mesh_fs_params[30].w, 0.0, 1.0);\n    }\n    bool _3515 = _3504 < 1.0;\n    bool _3521;\n    if (_3515)\n    {\n        int param = li;\n        _3521 = fa_light_baked(param);\n    }\n    else\n    {\n        _3521 = _3515;\n    }\n    return _3521 ? _3504 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _574 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _587 = (c - (ru * hx)) - p;\n        vec3 _593 = ru * (2.0 * hx);\n        float _599 = max(dot(_593, _593), 9.9999999392252902907785028219223e-09);\n        float _603 = dot(_587, _593);\n        float t = clamp((-_603) / _599, 0.0, 1.0);\n        if (_574)\n        {\n            float _618 = dot(r, _593);\n            float _624 = _599 - (_618 * _618);\n            if (abs(_624) > (9.9999997473787516355514526367188e-06 * _599))\n            {\n                t = clamp(((dot(r, _587) * _618) - _603) / _624, 0.0, 1.0);\n            }\n        }\n        return (p + _587) + (_593 * t);\n    }\n    vec3 q = p;\n    float _656 = dot(r, axis);\n    bool _664;\n    if (_574)\n    {\n        _664 = abs(_656) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _664 = _574;\n    }\n    if (_664)\n    {\n        float _674 = dot(c - p, axis) / _656;\n        if (_674 > 0.0)\n        {\n            q = p + (r * _674);\n        }\n    }\n    vec3 _687 = q - c;\n    vec2 xy = vec2(dot(_687, ru), dot(_687, uu));\n    if (shape > 0.5)\n    {\n        float _702 = length(xy);\n        if (_702 > hx)\n        {\n            xy *= (hx / _702);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _344 = abs(d);\n    float _346 = _344.x;\n    float _348 = _344.y;\n    bool _349 = _346 >= _348;\n    bool _357;\n    if (_349)\n    {\n        _357 = _346 >= _344.z;\n    }\n    else\n    {\n        _357 = _349;\n    }\n    int _358;\n    if (_357)\n    {\n        _358 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _373;\n        if (_348 >= _344.z)\n        {\n            _373 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _373 = (d.z > 0.0) ? 4 : 5;\n        }\n        _358 = _373;\n    }\n    return _358;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _494 = dot(d, right);\n    float _498 = dot(d, up);\n    float _509;\n    if (((_494 * _494) + (_498 * _498)) > 1.0000000133514319600180897396058e-10)\n    {\n        _509 = atan(_498, _494) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _509 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_509 - floor(_509)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _740 = fa_light_base(param);\n    bool _744 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _740;\n    vec4 _748 = fa_light_texel(param_1);\n    int param_2 = _740 + 1;\n    vec4 _753 = fa_light_texel(param_2);\n    float _756 = _753.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _768 = _744 && (_756 > 2.5);\n    fa_light_is_area = _768;\n    bool _770 = _756 < 0.5;\n    vec3 l;\n    if (_770)\n    {\n        l = normalize(_748.xyz);\n        if (_744)\n        {\n            int param_3 = _740 + 6;\n            vec4 _784 = fa_light_texel(param_3);\n            if (_784.z > 0.5)\n            {\n                int param_4 = _740 + 4;\n                vec4 _794 = fa_light_texel(param_4);\n                int param_5 = _740 + 5;\n                vec4 _799 = fa_light_texel(param_5);\n                vec2 param_6 = _784.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _794.xyz) * _794.w, (-dot(world_pos, _799.xyz)) * _799.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _829 = _748.xyz;\n        vec3 _831 = _829 - world_pos;\n        vec3 to_light = _831;\n        float _834 = length(_831);\n        float reach = _834;\n        bool front = true;\n        if (_768)\n        {\n            int param_8 = _740 + 7;\n            reach = max(_834 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _740 + 4;\n            vec4 _858 = fa_light_texel(param_9);\n            int param_10 = _740 + 5;\n            vec4 _863 = fa_light_texel(param_10);\n            int param_11 = _740 + 6;\n            vec4 _868 = fa_light_texel(param_11);\n            float _869 = _868.w;\n            int param_12 = _740 + 2;\n            vec3 _876 = normalize(fa_light_texel(param_12).xyz);\n            bool _878 = _869 > 1.5;\n            bool _886;\n            if (!_878)\n            {\n                _886 = dot(_876, to_light) < 0.0;\n            }\n            else\n            {\n                _886 = _878;\n            }\n            front = _886;\n            vec3 r = vec3(0.0);\n            vec3 _895 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _899 = dot(n, n) > 0.5;\n            bool _907;\n            if (_899)\n            {\n                _907 = dot(_895, _895) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _907 = _899;\n            }\n            if (_907)\n            {\n                r = reflect(-normalize(_895), normalize(n));\n            }\n            vec3 param_13 = _829;\n            vec3 param_14 = _876;\n            vec3 param_15 = _858.xyz;\n            vec3 param_16 = _863.xyz;\n            float param_17 = _858.w;\n            float param_18 = _863.w;\n            float param_19 = _869;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _943 = length(to_light);\n        dist = _943;\n        l = to_light / vec3(max(_943, 9.9999997473787516355514526367188e-05));\n        float _957 = reach / max(_748.w, 0.001000000047497451305389404296875);\n        float _963 = clamp(1.0 - (_957 * _957), 0.0, 1.0);\n        float _965;\n        if (front)\n        {\n            _965 = _963 * _963;\n        }\n        else\n        {\n            _965 = 0.0;\n        }\n        atten = _965;\n        bool _976 = _756 < 2.5;\n        if ((_756 > 1.5) && _976)\n        {\n            int param_22 = _740 + 2;\n            vec4 _984 = fa_light_texel(param_22);\n            float _994 = _984.w;\n            int param_23 = _740 + 3;\n            vec4 _999 = fa_light_texel(param_23);\n            float _1000 = _999.x;\n            float cos_inner = _1000;\n            if (_1000 > 1.5)\n            {\n                cos_inner = mix(_994, 1.0, 0.25);\n            }\n            atten *= smoothstep(_994, cos_inner, dot(-l, normalize(_984.xyz)));\n        }\n        if (_744 && (_756 < 1.5))\n        {\n            int param_24 = _740 + 6;\n            vec4 _1024 = fa_light_texel(param_24);\n            if (_1024.z > 0.5)\n            {\n                vec3 _1032 = -to_light;\n                int param_25 = _740 + 4;\n                int param_26 = _740 + 5;\n                vec3 _1046 = fa_light_texel(param_25).xyz;\n                vec3 _1050 = fa_light_texel(param_26).xyz;\n                vec3 _1059 = vec3(dot(_1032, _1046), dot(_1032, _1050), dot(_1032, cross(_1046, _1050)));\n                vec3 param_27 = _1059;\n                int _1063 = fa_cube_face(param_27);\n                int param_28 = _1063;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1090 = vec2(dot(_1059, cross(param_29, param_30)), dot(_1059, param_30)) / vec2(max(dot(_1059, param_29), 9.9999997473787516355514526367188e-05));\n                int _1094 = _1063 / 3;\n                vec2 param_31 = _1024.xy + (vec2(float(_1063 - (_1094 * 3)), float(_1094)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1090.x), 0.5 - (0.5 * _1090.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _740 + 7;\n            vec4 _1124 = fa_light_texel(param_33);\n            if (_1124.z > 0.5)\n            {\n                int param_34 = _740 + 2;\n                int param_35 = _740 + 4;\n                int param_36 = _740 + 5;\n                vec2 param_37 = _1124.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_744 && _976)\n            {\n                int param_42 = _740 + 6;\n                vec4 _1171 = fa_light_texel(param_42);\n                int param_43 = _740 + 7;\n                vec4 _1176 = fa_light_texel(param_43);\n                bool _1179 = _1171.z > 0.5;\n                bool _1186;\n                if (!_1179)\n                {\n                    _1186 = _1176.z > 0.5;\n                }\n                else\n                {\n                    _1186 = _1179;\n                }\n                if (_1186)\n                {\n                    int param_44 = _740 + 2;\n                    vec4 _1193 = fa_light_texel(param_44);\n                    vec3 _1197 = normalize(_1193.xyz);\n                    int param_45 = _740 + 4;\n                    vec4 _1202 = fa_light_texel(param_45);\n                    int param_46 = _740 + 5;\n                    vec4 _1207 = fa_light_texel(param_46);\n                    if (_1179)\n                    {\n                        vec3 _1215 = -to_light;\n                        float _1222 = _1193.w;\n                        float _1238 = 0.5 / max(dot(_1215, _1197) * (sqrt(max(1.0 - (_1222 * _1222), 0.0)) / max(_1222, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1171.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1215, _1202.xyz) * _1238), 0.5 - (dot(_1215, _1207.xyz) * _1238));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1176.z > 0.5)\n                    {\n                        vec2 param_49 = _1176.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1197;\n                        vec3 param_52 = _1202.xyz;\n                        vec3 param_53 = _1207.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _4680 = _753.xyz * atten;\n    if (_744)\n    {\n        _4680 *= fa_light_tint;\n    }\n    int _1306;\n    if (_770)\n    {\n        _1306 = 0;\n    }\n    else\n    {\n        _1306 = ((_756 > 1.5) && (_756 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4680, atten, 1.0, dist, _1306);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2043;\n    if (i == 0)\n    {\n        _2043 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2059;\n        if (i == 1)\n        {\n            _2059 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2067;\n            if (i == 2)\n            {\n                _2067 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2067 = fa_shadows[24].w;\n            }\n            _2059 = _2067;\n        }\n        _2043 = _2059;\n    }\n    return _2043;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2100 = fa_shadow_depth(param, param_1);\n    float _2104;\n    if (conv.x < 0.5)\n    {\n        _2104 = _2100;\n    }\n    else\n    {\n        _2104 = (conv.y * conv.z) / (conv.z - (_2100 * (conv.z - conv.y)));\n    }\n    return _2104;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2031 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2031), sin(_2031)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2150 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2159;\n        if (k < 0.0)\n        {\n            _2159 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2159 = k;\n        }\n        float _2179 = clamp((_2159 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2150;\n            vec2 _2198 = fa_shadow_vogel(param_3, param_4, param_5) * _2179;\n            vec2 param_6 = uv + (_2198 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2210 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2210 < (zr - (length(_2198) * plane)))\n            {\n                sum += _2210;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2236 = sum / cnt;\n        float _2246;\n        if (k < 0.0)\n        {\n            _2246 = (-k) / max(_2236, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2246 = k;\n        }\n        radius = clamp(((max(zr - _2236, 0.0) * unit) * _2246) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2268 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2268; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2268;\n        float param_11 = _2150;\n        vec2 _2287 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2287 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2287) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2268);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2329 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2334 = clamp(dot(n, l), 0.0, 1.0);\n    float _2340 = sqrt(1.0 - (_2334 * _2334));\n    float _2347 = min(_2340 / max(_2334, 0.20000000298023223876953125), 4.0);\n    float _2352;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2352 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2352 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2377 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2352 * _2340)), 1.0);\n    float _2384 = _2377.x;\n    bool _2387 = _2384 < fa_shadows[ci * 1 + 16].x;\n    bool _2396;\n    if (!_2387)\n    {\n        _2396 = _2384 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2396 = _2387;\n    }\n    bool _2405;\n    if (!_2396)\n    {\n        _2405 = _2377.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2405 = _2396;\n    }\n    bool _2414;\n    if (!_2405)\n    {\n        _2414 = _2377.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2414 = _2405;\n    }\n    bool _2421;\n    if (!_2414)\n    {\n        _2421 = _2377.z > 1.0;\n    }\n    else\n    {\n        _2421 = _2414;\n    }\n    if (_2421)\n    {\n        return -1.0;\n    }\n    float _2429;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2429 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2429 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2377.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2377.z - ((_2429 * (1.0 + (0.5 * _2347))) / _2329);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2329;\n    float param_5 = _2329 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2347, 3.0)) * 0.5) / _2329;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2807 = int(fa_shadows[25].x + 0.5);\n    if (_2807 < 1)\n    {\n        return 1.0;\n    }\n    float _2822 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2807 - 1;\n    if (_2822 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2834 = _2807 > 1;\n    bool _2841;\n    if (_2834)\n    {\n        _2841 = _2822 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2841 = _2834;\n    }\n    if (_2841)\n    {\n        ci = 1;\n    }\n    bool _2845 = _2807 > 2;\n    bool _2852;\n    if (_2845)\n    {\n        _2852 = _2822 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2852 = _2845;\n    }\n    if (_2852)\n    {\n        ci = 2;\n    }\n    bool _2856 = _2807 > 3;\n    bool _2863;\n    if (_2856)\n    {\n        _2863 = _2822 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2863 = _2856;\n    }\n    if (_2863)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2807)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2889 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2889;\n        if (_2889 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2914;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2914 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2914 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2933 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2914, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2944 = clamp((_2822 - (fa_shadow_split_at(param_7) - _2933)) / _2933, 0.0, 1.0);\n        if (_2944 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2807)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2965 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2965;\n                if (_2965 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2944);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2487 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2494;\n    if (!_2487)\n    {\n        _2494 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2494 = _2487;\n    }\n    if (_2494)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2507 = fa_light_texel(param);\n    float _2508 = _2507.x;\n    if (_2508 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2517 = int(_2508 + 0.5);\n    int param_1 = _2517;\n    vec4 _2521 = fa_light_texel(param_1);\n    int param_2 = _2517 + 1;\n    vec4 _2526 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2529 = _2521.y;\n    if (_2529 > 0.0)\n    {\n        float _2546 = 1.0 - smoothstep(0.75 * _2529, _2529, length(world - fa_shadows[27].xyz));\n        fade = _2546;\n        if (_2546 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2521.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2570 = (_2517 + 2) + (face * 6);\n    int param_4 = _2570;\n    int param_5 = _2570 + 1;\n    int param_6 = _2570 + 3;\n    vec4 _2584 = fa_light_texel(param_6);\n    int param_7 = _2570 + 4;\n    vec4 _2589 = fa_light_texel(param_7);\n    int param_8 = _2570 + 5;\n    vec4 _2594 = fa_light_texel(param_8);\n    float _2606 = _2594.x * max(dot(_2584, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2611 = clamp(dot(n, l), 0.0, 1.0);\n    float _2634 = clamp(dot(n, _2584.xyz), -1.0, 1.0);\n    float _2653 = min(sqrt(1.0 - (_2634 * _2634)) / max(abs(dot(n, world - lpos)) / max(dot(_2584, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2656 = _2526.y;\n    float _2658;\n    if (_2656 > 0.0)\n    {\n        _2658 = _2656;\n    }\n    else\n    {\n        _2658 = 1.5 * _2606;\n    }\n    vec4 _2678 = vec4(world + (n * (_2658 * sqrt(1.0 - (_2611 * _2611)))), 1.0);\n    float _2682 = dot(_2584, _2678);\n    float _2685 = _2594.y;\n    if (_2682 < _2685)\n    {\n        return 1.0;\n    }\n    vec2 _2700 = vec2(dot(fa_light_texel(param_4), _2678), dot(fa_light_texel(param_5), _2678)) / vec2(_2682);\n    float _2702 = _2700.x;\n    bool _2705 = _2702 < _2589.x;\n    bool _2714;\n    if (!_2705)\n    {\n        _2714 = _2702 > _2589.z;\n    }\n    else\n    {\n        _2714 = _2705;\n    }\n    bool _2723;\n    if (!_2714)\n    {\n        _2723 = _2700.y < _2589.y;\n    }\n    else\n    {\n        _2723 = _2714;\n    }\n    bool _2732;\n    if (!_2723)\n    {\n        _2732 = _2700.y > _2589.w;\n    }\n    else\n    {\n        _2732 = _2723;\n    }\n    if (_2732)\n    {\n        return 1.0;\n    }\n    float _2738 = _2526.x;\n    float _2740;\n    if (_2738 > 0.0)\n    {\n        _2740 = _2738;\n    }\n    else\n    {\n        _2740 = 1.5 * _2606;\n    }\n    vec2 param_9 = _2700;\n    vec4 param_10 = _2589;\n    float param_11 = _2682 - (_2740 * (1.0 + (0.5 * _2653)));\n    float param_12 = _2606;\n    float param_13 = 1.0;\n    float param_14 = _2594.z * 0.25;\n    float param_15 = (_2606 * min(_2653, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2685, _2594.z);\n    int param_17 = int(_2521.z + 0.5);\n    float param_18 = _2521.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3246 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3253;\n    if (!_3246)\n    {\n        _3253 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3253 = _3246;\n    }\n    if (_3253)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3266 = fa_light_texel(param);\n    float _3267 = _3266.y;\n    float len = _3267;\n    if (_3267 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3279 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3289 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3279);\n    if (_3289 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3295 = len;\n    float _3298 = min(_3295, 0.89999997615814208984375 * dist);\n    len = _3298;\n    float _3304 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3279);\n    float _3309 = _3304 + (0.5 * _3298);\n    vec3 _3315 = world + (gn * _3304);\n    float _3317 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3382;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3333 = (float(k) + _3317) * 0.083333335816860198974609375;\n        vec3 _3341 = _3315 + (l * (_3333 * len));\n        vec4 _3347 = vec4(_3341, 1.0);\n        float _3353 = dot(fa_mesh_fs_params[28], _3347);\n        if (_3353 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3373 = vec2(dot(fa_mesh_fs_params[26], _3347), dot(fa_mesh_fs_params[27], _3347)) / vec2(_3353);\n        float _3377 = _3373.x * 0.5;\n        float _3378 = _3377 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3382 = (_3373.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3382 = 0.5 - (_3373.y * 0.5);\n        }\n        bool _3398 = _3378 < 0.0;\n        bool _3405;\n        if (!_3398)\n        {\n            _3405 = _3378 >= 1.0;\n        }\n        else\n        {\n            _3405 = _3398;\n        }\n        bool _3412;\n        if (!_3405)\n        {\n            _3412 = _3382 < 0.0;\n        }\n        else\n        {\n            _3412 = _3405;\n        }\n        bool _3419;\n        if (!_3412)\n        {\n            _3419 = _3382 >= 1.0;\n        }\n        else\n        {\n            _3419 = _3412;\n        }\n        if (_3419)\n        {\n            break;\n        }\n        vec4 _3438 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_3378, _3382) * fa_mesh_fs_params[24].zw), 0);\n        if (_3438.w < 0.5)\n        {\n            continue;\n        }\n        float _3457 = (dot(fa_mesh_fs_params[29].xyz, _3341) + fa_mesh_fs_params[29].w) - _3438.x;\n        if ((_3457 > _3304) && (_3457 < _3309))\n        {\n            occ = max(occ, (1.0 - (_3333 * _3333)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3378, 0.5 - _3377), min(_3382, 1.0 - _3382))));\n        }\n    }\n    return 1.0 - (occ * _3289);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _3560 = fa_baked_keep(param);\n    if (_3560 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3586 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _4706 = _3586.color;\n    float _4707 = _3586.attenuation;\n    float _4708 = _3586.shadow;\n    bool _3589 = _3586.type == 0;\n    if (_3589 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3586.direction;\n        float _3600 = fa_shadow_factor(param_5, param_6);\n        _4708 = _3600;\n        _4706 *= _3600;\n    }\n    else\n    {\n        bool _3611 = _3586.type != 0;\n        bool _3617;\n        if (_3611)\n        {\n            _3617 = _4707 > 0.0;\n        }\n        else\n        {\n            _3617 = _3611;\n        }\n        if (_3617)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3586.direction;\n            float _3636 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4708 = _3636;\n            _4706 *= _3636;\n        }\n    }\n    bool _3646 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3652;\n    if (_3646)\n    {\n        _3652 = _4707 > 0.0;\n    }\n    else\n    {\n        _3652 = _3646;\n    }\n    if (_3652)\n    {\n        float _3659;\n        if (_3589)\n        {\n            _3659 = 1000000000.0;\n        }\n        else\n        {\n            _3659 = _3586._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _3586.direction;\n        float param_18 = _3659;\n        float _3677 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _4708 *= _3677;\n        _4706 *= _3677;\n    }\n    float _3690 = _4707;\n    float _3691 = _3690 * _3560;\n    _4707 = _3691;\n    vec3 _3695 = _4706;\n    vec3 _3696 = _3695 * _3560;\n    _4706 = _3696;\n    return LightSample(_3586.direction, _3696, _3691, _4708, _3586._distance, _3586.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2989 = int(fa_shadows[25].x + 0.5);\n    float _2999 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3004 = _2989 > 0;\n    bool _3013;\n    if (_3004)\n    {\n        int param = _2989 - 1;\n        _3013 = _2999 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3013 = _3004;\n    }\n    if (_3013)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3019 = _2989 > 1;\n        bool _3026;\n        if (_3019)\n        {\n            _3026 = _2999 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3026 = _3019;\n        }\n        if (_3026)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3032 = _2989 > 2;\n        bool _3039;\n        if (_3032)\n        {\n            _3039 = _2999 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3039 = _3032;\n        }\n        if (_3039)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3045 = _2989 > 3;\n        bool _3052;\n        if (_3045)\n        {\n            _3052 = _2999 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3052 = _3045;\n        }\n        if (_3052)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4522 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4522 = -_4522;\n    }\n    vec3 _4113 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4522, fa_world_tangent, fa_uv, fa_vertex_color, _4113, gl_FrontFacing);\n    Surface _4121 = fa_standard_surface(param_1);\n    vec3 _4561 = _4121.albedo;\n    float _4562 = _4121.alpha;\n    vec3 _4563 = _4121.normal;\n    float _4564 = _4121.metallic;\n    float _4565 = _4121.roughness;\n    float _4566 = _4121.occlusion;\n    vec3 _4567 = _4121.emission;\n    float _4568 = _4121.clearcoat;\n    float _4569 = _4121.clearcoat_roughness;\n    vec3 _4570 = _4121.sheen_color;\n    float _4571 = _4121.sheen_roughness;\n    float _4572 = _4121.anisotropy;\n    float _4573 = _4121.anisotropy_rotation;\n    float _4574 = _4121.specular;\n    float _4575 = _4121.ior;\n    vec3 _4576 = _4121.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4522, fa_world_tangent, fa_uv, fa_vertex_color, _4113, gl_FrontFacing);\n    Surface param_3 = _4121;\n    surface(param_2, param_3);\n    _4561 = param_3.albedo;\n    _4562 = param_3.alpha;\n    _4563 = param_3.normal;\n    _4564 = param_3.metallic;\n    _4565 = param_3.roughness;\n    _4566 = param_3.occlusion;\n    _4567 = param_3.emission;\n    _4568 = param_3.clearcoat;\n    _4569 = param_3.clearcoat_roughness;\n    _4570 = param_3.sheen_color;\n    _4571 = param_3.sheen_roughness;\n    _4572 = param_3.anisotropy;\n    _4573 = param_3.anisotropy_rotation;\n    _4574 = param_3.specular;\n    _4575 = param_3.ior;\n    _4576 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4522;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4561 = param_6;\n    _4563 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4561;\n    }\n    else\n    {\n        vec3 _4159 = _4563;\n        vec3 _4160 = normalize(_4159);\n        _4563 = _4160;\n        vec3 param_8 = _4160;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _4522, fa_world_tangent, fa_uv, fa_vertex_color, _4113, gl_FrontFacing);\n        Surface param_10 = Surface(_4561, _4562, _4563, _4564, _4565, _4566, _4567, _4568, _4569, _4570, _4571, _4572, _4573, _4574, _4575, _4576);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _4179 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4179; ln++)\n        {\n            int param_12 = ln;\n            int _4192 = fa_cl_light(param_12);\n            int param_13 = _4192;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _4192;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _4522;\n            LightSample _4208 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _4522, fa_world_tangent, fa_uv, fa_vertex_color, _4113, gl_FrontFacing);\n            Surface param_18 = Surface(_4561, _4562, _4563, _4564, _4565, _4566, _4567, _4568, _4569, _4570, _4571, _4572, _4573, _4574, _4575, _4576);\n            LightSample param_19 = _4208;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _4223 = result;\n    vec3 _4224 = _4223 + _4567;\n    result = _4224;\n    vec3 param_20 = _4224;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _4233 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4240;\n    if (!_4233)\n    {\n        _4240 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4240 = _4233;\n    }\n    if (_4240)\n    {\n        vec3 _4249 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4255 = dot(_4249, fa_mesh_fs_params[9].xyz);\n        bool _4259 = fa_mesh_fs_params[9].w > 0.5;\n        float _4260;\n        if (_4259)\n        {\n            _4260 = _4255;\n        }\n        else\n        {\n            _4260 = length(_4249);\n        }\n        float _4272 = _4260 - fa_mesh_fs_params[8].x;\n        if (_4272 > 0.0)\n        {\n            float _4281 = fa_mesh_fs_params[7].w * _4272;\n            float tau = _4281 * _4281;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4297;\n                if (_4259)\n                {\n                    _4297 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4255);\n                }\n                else\n                {\n                    _4297 = fa_mesh_fs_params[0].y;\n                }\n                float _4318 = mix(_4297, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4260, 0.0, 1.0));\n                float _4322 = fa_world_pos.y - _4318;\n                float _4327 = _4318 - fa_mesh_fs_params[8].z;\n                float _4332 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4335 = _4327 <= 0.0;\n                bool _4336 = !_4335;\n                bool _4342;\n                if (_4336)\n                {\n                    _4342 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4342 = _4335;\n                }\n                float _4343;\n                if (_4342)\n                {\n                    _4343 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4343 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4327, 80.0));\n                }\n                bool _4370;\n                if (_4336)\n                {\n                    _4370 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4370 = _4335;\n                }\n                float _4371;\n                if (_4370)\n                {\n                    _4371 = fa_mesh_fs_params[8].y * _4327;\n                }\n                else\n                {\n                    _4371 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4327, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4396 = _4332 <= 0.0;\n                bool _4403;\n                if (!_4396)\n                {\n                    _4403 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4403 = _4396;\n                }\n                float _4404;\n                if (_4403)\n                {\n                    _4404 = fa_mesh_fs_params[8].y * _4332;\n                }\n                else\n                {\n                    _4404 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4332, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4431;\n                if (abs(_4322) < 0.001000000047497451305389404296875)\n                {\n                    _4431 = _4343;\n                }\n                else\n                {\n                    _4431 = (_4404 - _4371) / _4322;\n                }\n                tau += (_4272 * max(_4431, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4562);\n}\n\n",
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
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_396",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 39,
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
            "inst_name": "_2053",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[39];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1324 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1331;\n    if (!_1324)\n    {\n        _1331 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1331 = _1324;\n    }\n    bool _1339;\n    if (!_1331)\n    {\n        _1339 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1339 = _1331;\n    }\n    bool _1346;\n    if (!_1339)\n    {\n        _1346 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1346 = _1339;\n    }\n    bool _1353;\n    if (!_1346)\n    {\n        _1353 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1353 = _1346;\n    }\n    if (_1353)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1363 = vec4(world_pos, 1.0);\n    float _1369 = dot(fa_mesh_fs_params[16], _1363);\n    if (!(_1369 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1391 = vec2(dot(fa_mesh_fs_params[14], _1363), dot(fa_mesh_fs_params[15], _1363)) / vec2(_1369);\n    int _1395 = int(fa_mesh_fs_params[18].x);\n    int _1399 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1399) + clamp(int(floor(((_1391.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1399 - 1)) * _1395)) + clamp(int(floor(((_1391.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1395 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1475 = fa_cluster_texel(param);\n    return ivec2(int(_1475.x), int(_1475.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3534 = fa_cluster_lookup(param);\n    fa_cl_slot = _3534.x;\n    fa_cl_local = _3534.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3744 = fa_linear_to_srgb(param);\n        c = _3744;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3752 = fa_srgb_to_linear(param_1);\n            c = _3752;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _278;\n    if (i.front_facing)\n    {\n        _278 = i.world_normal;\n    }\n    else\n    {\n        _278 = -i.world_normal;\n    }\n    vec3 _302 = normalize(i.world_tangent.xyz - (_278 * dot(_278, i.world_tangent.xyz)));\n    vec3 _329 = normalize(((_302 * m.x) + ((cross(_278, _302) * i.world_tangent.w) * m.y)) + (_278 * m.z));\n    vec3 _332;\n    if (i.front_facing)\n    {\n        _332 = _329;\n    }\n    else\n    {\n        _332 = -_329;\n    }\n    return _332;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3783 = fa_tex_fix(param_2, param_3);\n    vec4 _4874 = base_t;\n    _4874.x = _3783.x;\n    _4874.y = _3783.y;\n    _4874.z = _3783.z;\n    base_t = _4874;\n    vec4 _3797 = (_4874 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4726 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3829 = fa_tex_fix(param_6, param_7);\n        vec3 _3832 = (_3829 * 2.0) - vec3(1.0);\n        vec2 _3837 = _3832.xy * fa_mesh_fs_params[6].x;\n        vec3 _4882 = _3832;\n        _4882.x = _3837.x;\n        _4882.y = _3837.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4882;\n        _4726 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3865 = fa_tex_fix(param_12, param_13);\n    vec4 _4885 = mrt;\n    _4885.x = _3865.x;\n    _4885.y = _3865.y;\n    _4885.z = _3865.z;\n    mrt = _4885;\n    vec4 _3893 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3893.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3904 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3934 = fa_tex_fix(param_20, param_21);\n    float _4731 = fa_mesh_fs_params[20].x;\n    float _4732 = fa_mesh_fs_params[20].y;\n    float _4735 = fa_mesh_fs_params[20].z;\n    float _4734 = fa_mesh_fs_params[21].w;\n    float _4737 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4731 *= _3904.y;\n            _4732 *= _3904.z;\n            _4734 *= _3893.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4735 *= mrt.x;\n            _4737 *= mrt.w;\n        }\n    }\n    return Surface(_3797.xyz, _3797.w, _4726, clamp(fa_mesh_fs_params[5].x * _3865.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3865.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3904.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3934), _4731, _4732, fa_mesh_fs_params[21].xyz, _4734, _4735, fa_mesh_fs_params[20].w, _4737, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1555 = rect.zw - rect.xy;\n    vec2 _1559 = _1555 * atlas;\n    vec2 _1563 = ddx * _1559;\n    vec2 _1567 = ddy * _1559;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1555), clamp(0.5 * log2(max(max(dot(_1563, _1563), dot(_1567, _1567)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1600 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1607;\n    if (!_1600)\n    {\n        _1607 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1607 = _1600;\n    }\n    if (_1607)\n    {\n        return;\n    }\n    vec3 _1613 = dFdx(world_pos);\n    vec3 _1616 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1620 = fa_cluster_texel(param);\n    int _1624 = int(_1620.w);\n    if (_1624 < 1)\n    {\n        return;\n    }\n    int _1634 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1634;\n    vec4 _1638 = fa_light_texel(param_1);\n    vec2 _1641 = _1638.yz;\n    int _1645 = int(_1638.w);\n    int param_2 = _1634 + 1;\n    vec4 _1650 = fa_light_texel(param_2);\n    float _1651 = _1650.x;\n    int _1657 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1661 = int(_1620.z);\n    vec3 _1926;\n    for (int k = 0; k < _1624; k++)\n    {\n        int _1674 = _1661 + k;\n        int param_3 = _1645 + (_1674 >> 2);\n        int _1691 = (_1634 + 2) + (int(fa_light_texel(param_3)[_1674 & 3]) * 7);\n        int param_4 = _1691 + 6;\n        vec4 _1696 = fa_light_texel(param_4);\n        if (((int(_1696.w + 0.5) >> _1657) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1691;\n        vec4 _1711 = fa_light_texel(param_5);\n        int param_6 = _1691 + 1;\n        vec4 _1716 = fa_light_texel(param_6);\n        int param_7 = _1691 + 2;\n        vec4 _1721 = fa_light_texel(param_7);\n        vec3 _1724 = _1711.xyz;\n        float _1729 = dot(_1724, world_pos) + _1711.w;\n        vec3 _1731 = _1716.xyz;\n        float _1736 = dot(_1731, world_pos) + _1716.w;\n        vec3 _1738 = _1721.xyz;\n        float _1743 = dot(_1738, world_pos) + _1721.w;\n        bool _1748 = abs(_1729) > 0.5;\n        bool _1756;\n        if (!_1748)\n        {\n            _1756 = abs(_1736) > 0.5;\n        }\n        else\n        {\n            _1756 = _1748;\n        }\n        bool _1764;\n        if (!_1756)\n        {\n            _1764 = abs(_1743) > 0.5;\n        }\n        else\n        {\n            _1764 = _1756;\n        }\n        if (_1764)\n        {\n            continue;\n        }\n        float _1779 = clamp(dot(geo_normal, normalize(_1738)) * _1696.z, 0.0, 1.0);\n        if (_1779 <= 0.0)\n        {\n            continue;\n        }\n        float _1799 = (clamp((0.5 - abs(_1743)) * 10.0, 0.0, 1.0) * _1779) * _1696.x;\n        vec2 _1807 = vec2(_1729 + 0.5, 0.5 - _1736);\n        vec2 _1817 = vec2(dot(_1724, _1613), dot(_1731, _1613));\n        vec2 _1827 = vec2(dot(_1724, _1616), dot(_1731, _1616));\n        int param_8 = _1691 + 5;\n        vec4 _1832 = fa_light_texel(param_8);\n        int param_9 = _1691 + 3;\n        vec4 _1837 = fa_light_texel(param_9);\n        int param_10 = _1691 + 4;\n        vec4 _1842 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1832.xyz;\n        bool _1852 = _1837.z > _1837.x;\n        if (_1852)\n        {\n            vec4 param_11 = _1837;\n            vec2 param_12 = _1807;\n            vec2 param_13 = _1641;\n            vec2 param_14 = _1817;\n            vec2 param_15 = _1827;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1651 > 0.5) && (_1651 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1878 = fa_dc_to_linear(param_16);\n                vec4 _4806 = tx;\n                _4806.x = _1878.x;\n                _4806.y = _1878.y;\n                _4806.z = _1878.z;\n                tx = _4806;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1799 * tex_a) * _1832.w, 0.0, 1.0)));\n        if (_1842.z > _1842.x)\n        {\n            vec4 param_17 = _1842;\n            vec2 param_18 = _1807;\n            vec2 param_19 = _1641;\n            vec2 param_20 = _1817;\n            vec2 param_21 = _1827;\n            vec4 _1922 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1651 > 1.5)\n            {\n                vec3 param_22 = _1922.xyz;\n                vec3 _1932 = fa_dc_to_srgb(param_22);\n                _1926 = _1932;\n            }\n            else\n            {\n                _1926 = _1922.xyz;\n            }\n            vec3 _1941 = (_1926 * 2.0) - vec3(1.0);\n            vec2 _1946 = _1941.xy * _1696.y;\n            vec3 _1968 = (normalize(_1724) * _1946.x) + (normalize(_1731) * _1946.y);\n            vec3 _1971 = normalize(normal);\n            normal = normalize(mix(_1971, normalize((_1971 * max(_1941.z, 0.0500000007450580596923828125)) + (_1968 - (_1971 * dot(_1971, _1968)))), vec3(clamp(_1799 * (_1852 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3166 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3166;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[30].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 30].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[30].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3504;\n    if (fa_lm.z > 0.5)\n    {\n        _3504 = 0.0;\n    }\n    else\n    {\n        _3504 = 1.0 - clamp(fa_mesh_fs_params[30].w, 0.0, 1.0);\n    }\n    bool _3515 = _3504 < 1.0;\n    bool _3521;\n    if (_3515)\n    {\n        int param = li;\n        _3521 = fa_light_baked(param);\n    }\n    else\n    {\n        _3521 = _3515;\n    }\n    return _3521 ? _3504 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _574 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _587 = (c - (ru * hx)) - p;\n        vec3 _593 = ru * (2.0 * hx);\n        float _599 = max(dot(_593, _593), 9.9999999392252902907785028219223e-09);\n        float _603 = dot(_587, _593);\n        float t = clamp((-_603) / _599, 0.0, 1.0);\n        if (_574)\n        {\n            float _618 = dot(r, _593);\n            float _624 = _599 - (_618 * _618);\n            if (abs(_624) > (9.9999997473787516355514526367188e-06 * _599))\n            {\n                t = clamp(((dot(r, _587) * _618) - _603) / _624, 0.0, 1.0);\n            }\n        }\n        return (p + _587) + (_593 * t);\n    }\n    vec3 q = p;\n    float _656 = dot(r, axis);\n    bool _664;\n    if (_574)\n    {\n        _664 = abs(_656) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _664 = _574;\n    }\n    if (_664)\n    {\n        float _674 = dot(c - p, axis) / _656;\n        if (_674 > 0.0)\n        {\n            q = p + (r * _674);\n        }\n    }\n    vec3 _687 = q - c;\n    vec2 xy = vec2(dot(_687, ru), dot(_687, uu));\n    if (shape > 0.5)\n    {\n        float _702 = length(xy);\n        if (_702 > hx)\n        {\n            xy *= (hx / _702);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _344 = abs(d);\n    float _346 = _344.x;\n    float _348 = _344.y;\n    bool _349 = _346 >= _348;\n    bool _357;\n    if (_349)\n    {\n        _357 = _346 >= _344.z;\n    }\n    else\n    {\n        _357 = _349;\n    }\n    int _358;\n    if (_357)\n    {\n        _358 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _373;\n        if (_348 >= _344.z)\n        {\n            _373 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _373 = (d.z > 0.0) ? 4 : 5;\n        }\n        _358 = _373;\n    }\n    return _358;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _494 = dot(d, right);\n    float _498 = dot(d, up);\n    float _509;\n    if (((_494 * _494) + (_498 * _498)) > 1.0000000133514319600180897396058e-10)\n    {\n        _509 = atan(_498, _494) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _509 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_509 - floor(_509)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _740 = fa_light_base(param);\n    bool _744 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _740;\n    vec4 _748 = fa_light_texel(param_1);\n    int param_2 = _740 + 1;\n    vec4 _753 = fa_light_texel(param_2);\n    float _756 = _753.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _768 = _744 && (_756 > 2.5);\n    fa_light_is_area = _768;\n    bool _770 = _756 < 0.5;\n    vec3 l;\n    if (_770)\n    {\n        l = normalize(_748.xyz);\n        if (_744)\n        {\n            int param_3 = _740 + 6;\n            vec4 _784 = fa_light_texel(param_3);\n            if (_784.z > 0.5)\n            {\n                int param_4 = _740 + 4;\n                vec4 _794 = fa_light_texel(param_4);\n                int param_5 = _740 + 5;\n                vec4 _799 = fa_light_texel(param_5);\n                vec2 param_6 = _784.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _794.xyz) * _794.w, (-dot(world_pos, _799.xyz)) * _799.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _829 = _748.xyz;\n        vec3 _831 = _829 - world_pos;\n        vec3 to_light = _831;\n        float _834 = length(_831);\n        float reach = _834;\n        bool front = true;\n        if (_768)\n        {\n            int param_8 = _740 + 7;\n            reach = max(_834 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _740 + 4;\n            vec4 _858 = fa_light_texel(param_9);\n            int param_10 = _740 + 5;\n            vec4 _863 = fa_light_texel(param_10);\n            int param_11 = _740 + 6;\n            vec4 _868 = fa_light_texel(param_11);\n            float _869 = _868.w;\n            int param_12 = _740 + 2;\n            vec3 _876 = normalize(fa_light_texel(param_12).xyz);\n            bool _878 = _869 > 1.5;\n            bool _886;\n            if (!_878)\n            {\n                _886 = dot(_876, to_light) < 0.0;\n            }\n            else\n            {\n                _886 = _878;\n            }\n            front = _886;\n            vec3 r = vec3(0.0);\n            vec3 _895 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _899 = dot(n, n) > 0.5;\n            bool _907;\n            if (_899)\n            {\n                _907 = dot(_895, _895) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _907 = _899;\n            }\n            if (_907)\n            {\n                r = reflect(-normalize(_895), normalize(n));\n            }\n            vec3 param_13 = _829;\n            vec3 param_14 = _876;\n            vec3 param_15 = _858.xyz;\n            vec3 param_16 = _863.xyz;\n            float param_17 = _858.w;\n            float param_18 = _863.w;\n            float param_19 = _869;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _943 = length(to_light);\n        dist = _943;\n        l = to_light / vec3(max(_943, 9.9999997473787516355514526367188e-05));\n        float _957 = reach / max(_748.w, 0.001000000047497451305389404296875);\n        float _963 = clamp(1.0 - (_957 * _957), 0.0, 1.0);\n        float _965;\n        if (front)\n        {\n            _965 = _963 * _963;\n        }\n        else\n        {\n            _965 = 0.0;\n        }\n        atten = _965;\n        bool _976 = _756 < 2.5;\n        if ((_756 > 1.5) && _976)\n        {\n            int param_22 = _740 + 2;\n            vec4 _984 = fa_light_texel(param_22);\n            float _994 = _984.w;\n            int param_23 = _740 + 3;\n            vec4 _999 = fa_light_texel(param_23);\n            float _1000 = _999.x;\n            float cos_inner = _1000;\n            if (_1000 > 1.5)\n            {\n                cos_inner = mix(_994, 1.0, 0.25);\n            }\n            atten *= smoothstep(_994, cos_inner, dot(-l, normalize(_984.xyz)));\n        }\n        if (_744 && (_756 < 1.5))\n        {\n            int param_24 = _740 + 6;\n            vec4 _1024 = fa_light_texel(param_24);\n            if (_1024.z > 0.5)\n            {\n                vec3 _1032 = -to_light;\n                int param_25 = _740 + 4;\n                int param_26 = _740 + 5;\n                vec3 _1046 = fa_light_texel(param_25).xyz;\n                vec3 _1050 = fa_light_texel(param_26).xyz;\n                vec3 _1059 = vec3(dot(_1032, _1046), dot(_1032, _1050), dot(_1032, cross(_1046, _1050)));\n                vec3 param_27 = _1059;\n                int _1063 = fa_cube_face(param_27);\n                int param_28 = _1063;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1090 = vec2(dot(_1059, cross(param_29, param_30)), dot(_1059, param_30)) / vec2(max(dot(_1059, param_29), 9.9999997473787516355514526367188e-05));\n                int _1094 = _1063 / 3;\n                vec2 param_31 = _1024.xy + (vec2(float(_1063 - (_1094 * 3)), float(_1094)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1090.x), 0.5 - (0.5 * _1090.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _740 + 7;\n            vec4 _1124 = fa_light_texel(param_33);\n            if (_1124.z > 0.5)\n            {\n                int param_34 = _740 + 2;\n                int param_35 = _740 + 4;\n                int param_36 = _740 + 5;\n                vec2 param_37 = _1124.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_744 && _976)\n            {\n                int param_42 = _740 + 6;\n                vec4 _1171 = fa_light_texel(param_42);\n                int param_43 = _740 + 7;\n                vec4 _1176 = fa_light_texel(param_43);\n                bool _1179 = _1171.z > 0.5;\n                bool _1186;\n                if (!_1179)\n                {\n                    _1186 = _1176.z > 0.5;\n                }\n                else\n                {\n                    _1186 = _1179;\n                }\n                if (_1186)\n                {\n                    int param_44 = _740 + 2;\n                    vec4 _1193 = fa_light_texel(param_44);\n                    vec3 _1197 = normalize(_1193.xyz);\n                    int param_45 = _740 + 4;\n                    vec4 _1202 = fa_light_texel(param_45);\n                    int param_46 = _740 + 5;\n                    vec4 _1207 = fa_light_texel(param_46);\n                    if (_1179)\n                    {\n                        vec3 _1215 = -to_light;\n                        float _1222 = _1193.w;\n                        float _1238 = 0.5 / max(dot(_1215, _1197) * (sqrt(max(1.0 - (_1222 * _1222), 0.0)) / max(_1222, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1171.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1215, _1202.xyz) * _1238), 0.5 - (dot(_1215, _1207.xyz) * _1238));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1176.z > 0.5)\n                    {\n                        vec2 param_49 = _1176.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1197;\n                        vec3 param_52 = _1202.xyz;\n                        vec3 param_53 = _1207.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _4680 = _753.xyz * atten;\n    if (_744)\n    {\n        _4680 *= fa_light_tint;\n    }\n    int _1306;\n    if (_770)\n    {\n        _1306 = 0;\n    }\n    else\n    {\n        _1306 = ((_756 > 1.5) && (_756 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4680, atten, 1.0, dist, _1306);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2043;\n    if (i == 0)\n    {\n        _2043 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2059;\n        if (i == 1)\n        {\n            _2059 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2067;\n            if (i == 2)\n            {\n                _2067 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2067 = fa_shadows[24].w;\n            }\n            _2059 = _2067;\n        }\n        _2043 = _2059;\n    }\n    return _2043;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2100 = fa_shadow_depth(param, param_1);\n    float _2104;\n    if (conv.x < 0.5)\n    {\n        _2104 = _2100;\n    }\n    else\n    {\n        _2104 = (conv.y * conv.z) / (conv.z - (_2100 * (conv.z - conv.y)));\n    }\n    return _2104;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2031 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2031), sin(_2031)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2150 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2159;\n        if (k < 0.0)\n        {\n            _2159 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2159 = k;\n        }\n        float _2179 = clamp((_2159 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2150;\n            vec2 _2198 = fa_shadow_vogel(param_3, param_4, param_5) * _2179;\n            vec2 param_6 = uv + (_2198 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2210 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2210 < (zr - (length(_2198) * plane)))\n            {\n                sum += _2210;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2236 = sum / cnt;\n        float _2246;\n        if (k < 0.0)\n        {\n            _2246 = (-k) / max(_2236, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2246 = k;\n        }\n        radius = clamp(((max(zr - _2236, 0.0) * unit) * _2246) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2268 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2268; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2268;\n        float param_11 = _2150;\n        vec2 _2287 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2287 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2287) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2268);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2329 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2334 = clamp(dot(n, l), 0.0, 1.0);\n    float _2340 = sqrt(1.0 - (_2334 * _2334));\n    float _2347 = min(_2340 / max(_2334, 0.20000000298023223876953125), 4.0);\n    float _2352;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2352 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2352 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2377 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2352 * _2340)), 1.0);\n    float _2384 = _2377.x;\n    bool _2387 = _2384 < fa_shadows[ci * 1 + 16].x;\n    bool _2396;\n    if (!_2387)\n    {\n        _2396 = _2384 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2396 = _2387;\n    }\n    bool _2405;\n    if (!_2396)\n    {\n        _2405 = _2377.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2405 = _2396;\n    }\n    bool _2414;\n    if (!_2405)\n    {\n        _2414 = _2377.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2414 = _2405;\n    }\n    bool _2421;\n    if (!_2414)\n    {\n        _2421 = _2377.z > 1.0;\n    }\n    else\n    {\n        _2421 = _2414;\n    }\n    if (_2421)\n    {\n        return -1.0;\n    }\n    float _2429;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2429 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2429 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2377.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2377.z - ((_2429 * (1.0 + (0.5 * _2347))) / _2329);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2329;\n    float param_5 = _2329 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2347, 3.0)) * 0.5) / _2329;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2807 = int(fa_shadows[25].x + 0.5);\n    if (_2807 < 1)\n    {\n        return 1.0;\n    }\n    float _2822 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2807 - 1;\n    if (_2822 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2834 = _2807 > 1;\n    bool _2841;\n    if (_2834)\n    {\n        _2841 = _2822 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2841 = _2834;\n    }\n    if (_2841)\n    {\n        ci = 1;\n    }\n    bool _2845 = _2807 > 2;\n    bool _2852;\n    if (_2845)\n    {\n        _2852 = _2822 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2852 = _2845;\n    }\n    if (_2852)\n    {\n        ci = 2;\n    }\n    bool _2856 = _2807 > 3;\n    bool _2863;\n    if (_2856)\n    {\n        _2863 = _2822 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2863 = _2856;\n    }\n    if (_2863)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2807)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2889 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2889;\n        if (_2889 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2914;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2914 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2914 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2933 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2914, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2944 = clamp((_2822 - (fa_shadow_split_at(param_7) - _2933)) / _2933, 0.0, 1.0);\n        if (_2944 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2807)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2965 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2965;\n                if (_2965 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2944);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2487 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2494;\n    if (!_2487)\n    {\n        _2494 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2494 = _2487;\n    }\n    if (_2494)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2507 = fa_light_texel(param);\n    float _2508 = _2507.x;\n    if (_2508 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2517 = int(_2508 + 0.5);\n    int param_1 = _2517;\n    vec4 _2521 = fa_light_texel(param_1);\n    int param_2 = _2517 + 1;\n    vec4 _2526 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2529 = _2521.y;\n    if (_2529 > 0.0)\n    {\n        float _2546 = 1.0 - smoothstep(0.75 * _2529, _2529, length(world - fa_shadows[27].xyz));\n        fade = _2546;\n        if (_2546 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2521.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2570 = (_2517 + 2) + (face * 6);\n    int param_4 = _2570;\n    int param_5 = _2570 + 1;\n    int param_6 = _2570 + 3;\n    vec4 _2584 = fa_light_texel(param_6);\n    int param_7 = _2570 + 4;\n    vec4 _2589 = fa_light_texel(param_7);\n    int param_8 = _2570 + 5;\n    vec4 _2594 = fa_light_texel(param_8);\n    float _2606 = _2594.x * max(dot(_2584, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2611 = clamp(dot(n, l), 0.0, 1.0);\n    float _2634 = clamp(dot(n, _2584.xyz), -1.0, 1.0);\n    float _2653 = min(sqrt(1.0 - (_2634 * _2634)) / max(abs(dot(n, world - lpos)) / max(dot(_2584, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2656 = _2526.y;\n    float _2658;\n    if (_2656 > 0.0)\n    {\n        _2658 = _2656;\n    }\n    else\n    {\n        _2658 = 1.5 * _2606;\n    }\n    vec4 _2678 = vec4(world + (n * (_2658 * sqrt(1.0 - (_2611 * _2611)))), 1.0);\n    float _2682 = dot(_2584, _2678);\n    float _2685 = _2594.y;\n    if (_2682 < _2685)\n    {\n        return 1.0;\n    }\n    vec2 _2700 = vec2(dot(fa_light_texel(param_4), _2678), dot(fa_light_texel(param_5), _2678)) / vec2(_2682);\n    float _2702 = _2700.x;\n    bool _2705 = _2702 < _2589.x;\n    bool _2714;\n    if (!_2705)\n    {\n        _2714 = _2702 > _2589.z;\n    }\n    else\n    {\n        _2714 = _2705;\n    }\n    bool _2723;\n    if (!_2714)\n    {\n        _2723 = _2700.y < _2589.y;\n    }\n    else\n    {\n        _2723 = _2714;\n    }\n    bool _2732;\n    if (!_2723)\n    {\n        _2732 = _2700.y > _2589.w;\n    }\n    else\n    {\n        _2732 = _2723;\n    }\n    if (_2732)\n    {\n        return 1.0;\n    }\n    float _2738 = _2526.x;\n    float _2740;\n    if (_2738 > 0.0)\n    {\n        _2740 = _2738;\n    }\n    else\n    {\n        _2740 = 1.5 * _2606;\n    }\n    vec2 param_9 = _2700;\n    vec4 param_10 = _2589;\n    float param_11 = _2682 - (_2740 * (1.0 + (0.5 * _2653)));\n    float param_12 = _2606;\n    float param_13 = 1.0;\n    float param_14 = _2594.z * 0.25;\n    float param_15 = (_2606 * min(_2653, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2685, _2594.z);\n    int param_17 = int(_2521.z + 0.5);\n    float param_18 = _2521.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3246 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3253;\n    if (!_3246)\n    {\n        _3253 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3253 = _3246;\n    }\n    if (_3253)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3266 = fa_light_texel(param);\n    float _3267 = _3266.y;\n    float len = _3267;\n    if (_3267 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3279 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3289 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3279);\n    if (_3289 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3295 = len;\n    float _3298 = min(_3295, 0.89999997615814208984375 * dist);\n    len = _3298;\n    float _3304 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3279);\n    float _3309 = _3304 + (0.5 * _3298);\n    vec3 _3315 = world + (gn * _3304);\n    float _3317 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3382;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3333 = (float(k) + _3317) * 0.083333335816860198974609375;\n        vec3 _3341 = _3315 + (l * (_3333 * len));\n        vec4 _3347 = vec4(_3341, 1.0);\n        float _3353 = dot(fa_mesh_fs_params[28], _3347);\n        if (_3353 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3373 = vec2(dot(fa_mesh_fs_params[26], _3347), dot(fa_mesh_fs_params[27], _3347)) / vec2(_3353);\n        float _3377 = _3373.x * 0.5;\n        float _3378 = _3377 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3382 = (_3373.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3382 = 0.5 - (_3373.y * 0.5);\n        }\n        bool _3398 = _3378 < 0.0;\n        bool _3405;\n        if (!_3398)\n        {\n            _3405 = _3378 >= 1.0;\n        }\n        else\n        {\n            _3405 = _3398;\n        }\n        bool _3412;\n        if (!_3405)\n        {\n            _3412 = _3382 < 0.0;\n        }\n        else\n        {\n            _3412 = _3405;\n        }\n        bool _3419;\n        if (!_3412)\n        {\n            _3419 = _3382 >= 1.0;\n        }\n        else\n        {\n            _3419 = _3412;\n        }\n        if (_3419)\n        {\n            break;\n        }\n        vec4 _3438 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_3378, _3382) * fa_mesh_fs_params[24].zw), 0);\n        if (_3438.w < 0.5)\n        {\n            continue;\n        }\n        float _3457 = (dot(fa_mesh_fs_params[29].xyz, _3341) + fa_mesh_fs_params[29].w) - _3438.x;\n        if ((_3457 > _3304) && (_3457 < _3309))\n        {\n            occ = max(occ, (1.0 - (_3333 * _3333)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3378, 0.5 - _3377), min(_3382, 1.0 - _3382))));\n        }\n    }\n    return 1.0 - (occ * _3289);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _3560 = fa_baked_keep(param);\n    if (_3560 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3586 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _4706 = _3586.color;\n    float _4707 = _3586.attenuation;\n    float _4708 = _3586.shadow;\n    bool _3589 = _3586.type == 0;\n    if (_3589 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3586.direction;\n        float _3600 = fa_shadow_factor(param_5, param_6);\n        _4708 = _3600;\n        _4706 *= _3600;\n    }\n    else\n    {\n        bool _3611 = _3586.type != 0;\n        bool _3617;\n        if (_3611)\n        {\n            _3617 = _4707 > 0.0;\n        }\n        else\n        {\n            _3617 = _3611;\n        }\n        if (_3617)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3586.direction;\n            float _3636 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4708 = _3636;\n            _4706 *= _3636;\n        }\n    }\n    bool _3646 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3652;\n    if (_3646)\n    {\n        _3652 = _4707 > 0.0;\n    }\n    else\n    {\n        _3652 = _3646;\n    }\n    if (_3652)\n    {\n        float _3659;\n        if (_3589)\n        {\n            _3659 = 1000000000.0;\n        }\n        else\n        {\n            _3659 = _3586._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _3586.direction;\n        float param_18 = _3659;\n        float _3677 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _4708 *= _3677;\n        _4706 *= _3677;\n    }\n    float _3690 = _4707;\n    float _3691 = _3690 * _3560;\n    _4707 = _3691;\n    vec3 _3695 = _4706;\n    vec3 _3696 = _3695 * _3560;\n    _4706 = _3696;\n    return LightSample(_3586.direction, _3696, _3691, _4708, _3586._distance, _3586.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2989 = int(fa_shadows[25].x + 0.5);\n    float _2999 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3004 = _2989 > 0;\n    bool _3013;\n    if (_3004)\n    {\n        int param = _2989 - 1;\n        _3013 = _2999 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3013 = _3004;\n    }\n    if (_3013)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3019 = _2989 > 1;\n        bool _3026;\n        if (_3019)\n        {\n            _3026 = _2999 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3026 = _3019;\n        }\n        if (_3026)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3032 = _2989 > 2;\n        bool _3039;\n        if (_3032)\n        {\n            _3039 = _2999 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3039 = _3032;\n        }\n        if (_3039)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3045 = _2989 > 3;\n        bool _3052;\n        if (_3045)\n        {\n            _3052 = _2999 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3052 = _3045;\n        }\n        if (_3052)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4522 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4522 = -_4522;\n    }\n    vec3 _4113 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4522, fa_world_tangent, fa_uv, fa_vertex_color, _4113, gl_FrontFacing);\n    Surface _4121 = fa_standard_surface(param_1);\n    vec3 _4561 = _4121.albedo;\n    float _4562 = _4121.alpha;\n    vec3 _4563 = _4121.normal;\n    float _4564 = _4121.metallic;\n    float _4565 = _4121.roughness;\n    float _4566 = _4121.occlusion;\n    vec3 _4567 = _4121.emission;\n    float _4568 = _4121.clearcoat;\n    float _4569 = _4121.clearcoat_roughness;\n    vec3 _4570 = _4121.sheen_color;\n    float _4571 = _4121.sheen_roughness;\n    float _4572 = _4121.anisotropy;\n    float _4573 = _4121.anisotropy_rotation;\n    float _4574 = _4121.specular;\n    float _4575 = _4121.ior;\n    vec3 _4576 = _4121.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4522, fa_world_tangent, fa_uv, fa_vertex_color, _4113, gl_FrontFacing);\n    Surface param_3 = _4121;\n    surface(param_2, param_3);\n    _4561 = param_3.albedo;\n    _4562 = param_3.alpha;\n    _4563 = param_3.normal;\n    _4564 = param_3.metallic;\n    _4565 = param_3.roughness;\n    _4566 = param_3.occlusion;\n    _4567 = param_3.emission;\n    _4568 = param_3.clearcoat;\n    _4569 = param_3.clearcoat_roughness;\n    _4570 = param_3.sheen_color;\n    _4571 = param_3.sheen_roughness;\n    _4572 = param_3.anisotropy;\n    _4573 = param_3.anisotropy_rotation;\n    _4574 = param_3.specular;\n    _4575 = param_3.ior;\n    _4576 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4522;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4561 = param_6;\n    _4563 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4561;\n    }\n    else\n    {\n        vec3 _4159 = _4563;\n        vec3 _4160 = normalize(_4159);\n        _4563 = _4160;\n        vec3 param_8 = _4160;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _4522, fa_world_tangent, fa_uv, fa_vertex_color, _4113, gl_FrontFacing);\n        Surface param_10 = Surface(_4561, _4562, _4563, _4564, _4565, _4566, _4567, _4568, _4569, _4570, _4571, _4572, _4573, _4574, _4575, _4576);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _4179 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4179; ln++)\n        {\n            int param_12 = ln;\n            int _4192 = fa_cl_light(param_12);\n            int param_13 = _4192;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _4192;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _4522;\n            LightSample _4208 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _4522, fa_world_tangent, fa_uv, fa_vertex_color, _4113, gl_FrontFacing);\n            Surface param_18 = Surface(_4561, _4562, _4563, _4564, _4565, _4566, _4567, _4568, _4569, _4570, _4571, _4572, _4573, _4574, _4575, _4576);\n            LightSample param_19 = _4208;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _4223 = result;\n    vec3 _4224 = _4223 + _4567;\n    result = _4224;\n    vec3 param_20 = _4224;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _4233 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4240;\n    if (!_4233)\n    {\n        _4240 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4240 = _4233;\n    }\n    if (_4240)\n    {\n        vec3 _4249 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4255 = dot(_4249, fa_mesh_fs_params[9].xyz);\n        bool _4259 = fa_mesh_fs_params[9].w > 0.5;\n        float _4260;\n        if (_4259)\n        {\n            _4260 = _4255;\n        }\n        else\n        {\n            _4260 = length(_4249);\n        }\n        float _4272 = _4260 - fa_mesh_fs_params[8].x;\n        if (_4272 > 0.0)\n        {\n            float _4281 = fa_mesh_fs_params[7].w * _4272;\n            float tau = _4281 * _4281;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4297;\n                if (_4259)\n                {\n                    _4297 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4255);\n                }\n                else\n                {\n                    _4297 = fa_mesh_fs_params[0].y;\n                }\n                float _4318 = mix(_4297, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4260, 0.0, 1.0));\n                float _4322 = fa_world_pos.y - _4318;\n                float _4327 = _4318 - fa_mesh_fs_params[8].z;\n                float _4332 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4335 = _4327 <= 0.0;\n                bool _4336 = !_4335;\n                bool _4342;\n                if (_4336)\n                {\n                    _4342 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4342 = _4335;\n                }\n                float _4343;\n                if (_4342)\n                {\n                    _4343 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4343 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4327, 80.0));\n                }\n                bool _4370;\n                if (_4336)\n                {\n                    _4370 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4370 = _4335;\n                }\n                float _4371;\n                if (_4370)\n                {\n                    _4371 = fa_mesh_fs_params[8].y * _4327;\n                }\n                else\n                {\n                    _4371 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4327, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4396 = _4332 <= 0.0;\n                bool _4403;\n                if (!_4396)\n                {\n                    _4403 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4403 = _4396;\n                }\n                float _4404;\n                if (_4403)\n                {\n                    _4404 = fa_mesh_fs_params[8].y * _4332;\n                }\n                else\n                {\n                    _4404 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4332, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4431;\n                if (abs(_4322) < 0.001000000047497451305389404296875)\n                {\n                    _4431 = _4343;\n                }\n                else\n                {\n                    _4431 = (_4404 - _4371) / _4322;\n                }\n                tau += (_4272 * max(_4431, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4562);\n}\n\n",
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
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_396",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 39,
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
            "inst_name": "_2053",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[39];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _787 = base_t;\n    _787.x = _227.x;\n    _787.y = _227.y;\n    _787.z = _227.z;\n    base_t = _787;\n    vec4 _243 = (_787 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _750 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _795 = _281;\n        _795.x = _286.x;\n        _795.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _798 = mrt;\n    _798.x = _315.x;\n    _798.y = _315.y;\n    _798.z = _315.z;\n    mrt = _798;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _755 = fa_mesh_fs_params[20].x;\n    float _756 = fa_mesh_fs_params[20].y;\n    float _759 = fa_mesh_fs_params[20].z;\n    float _758 = fa_mesh_fs_params[21].w;\n    float _761 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _755 *= _357.y;\n            _756 *= _357.z;\n            _758 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _750, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _755, _756, fa_mesh_fs_params[21].xyz, _758, _759, fa_mesh_fs_params[20].w, _761, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _661 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    vec3 _521 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _536 = normalize(param_2.normal);\n    vec3 _551 = normalize(vec3(dot(fa_pre_r0, _536), dot(fa_pre_r1, _536), dot(fa_pre_r2, _536)));\n    float _563 = _551.z;\n    vec2 e = _551.xy / vec2((abs(_551.x) + abs(_551.y)) + abs(_563));\n    if (_563 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_215",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 39,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[39];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _787 = base_t;\n    _787.x = _227.x;\n    _787.y = _227.y;\n    _787.z = _227.z;\n    base_t = _787;\n    vec4 _243 = (_787 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _750 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _795 = _281;\n        _795.x = _286.x;\n        _795.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _798 = mrt;\n    _798.x = _315.x;\n    _798.y = _315.y;\n    _798.z = _315.z;\n    mrt = _798;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _755 = fa_mesh_fs_params[20].x;\n    float _756 = fa_mesh_fs_params[20].y;\n    float _759 = fa_mesh_fs_params[20].z;\n    float _758 = fa_mesh_fs_params[21].w;\n    float _761 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _755 *= _357.y;\n            _756 *= _357.z;\n            _758 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _750, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _755, _756, fa_mesh_fs_params[21].xyz, _758, _759, fa_mesh_fs_params[20].w, _761, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _661 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    vec3 _521 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _536 = normalize(param_2.normal);\n    vec3 _551 = normalize(vec3(dot(fa_pre_r0, _536), dot(fa_pre_r1, _536), dot(fa_pre_r2, _536)));\n    float _563 = _551.z;\n    vec2 e = _551.xy / vec2((abs(_551.x) + abs(_551.y)) + abs(_563));\n    if (_563 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_215",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 39,
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
