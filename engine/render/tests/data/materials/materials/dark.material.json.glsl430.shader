{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "e0c1f830a27b422ba9d050f4a118de89d0d8c6a78e3cc09d7dad74ea546b40a2",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1349 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1356;\n    if (!_1349)\n    {\n        _1356 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1356 = _1349;\n    }\n    bool _1364;\n    if (!_1356)\n    {\n        _1364 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1364 = _1356;\n    }\n    bool _1371;\n    if (!_1364)\n    {\n        _1371 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1371 = _1364;\n    }\n    bool _1378;\n    if (!_1371)\n    {\n        _1378 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1378 = _1371;\n    }\n    if (_1378)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1388 = vec4(world_pos, 1.0);\n    float _1394 = dot(fa_mesh_fs_params[16], _1388);\n    if (!(_1394 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1416 = vec2(dot(fa_mesh_fs_params[14], _1388), dot(fa_mesh_fs_params[15], _1388)) / vec2(_1394);\n    int _1420 = int(fa_mesh_fs_params[18].x);\n    int _1424 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1424) + clamp(int(floor(((_1416.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1424 - 1)) * _1420)) + clamp(int(floor(((_1416.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1420 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1500 = fa_cluster_texel(param);\n    return ivec2(int(_1500.x), int(_1500.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4205 = fa_cluster_lookup(param);\n    fa_cl_slot = _4205.x;\n    fa_cl_local = _4205.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4410 = fa_linear_to_srgb(param);\n        c = _4410;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4418 = fa_srgb_to_linear(param_1);\n            c = _4418;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _303;\n    if (i.front_facing)\n    {\n        _303 = i.world_normal;\n    }\n    else\n    {\n        _303 = -i.world_normal;\n    }\n    vec3 _327 = normalize(i.world_tangent.xyz - (_303 * dot(_303, i.world_tangent.xyz)));\n    vec3 _354 = normalize(((_327 * m.x) + ((cross(_303, _327) * i.world_tangent.w) * m.y)) + (_303 * m.z));\n    vec3 _357;\n    if (i.front_facing)\n    {\n        _357 = _354;\n    }\n    else\n    {\n        _357 = -_354;\n    }\n    return _357;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4450 = fa_tex_fix(param_2, param_3);\n    vec4 _6326 = base_t;\n    _6326.x = _4450.x;\n    _6326.y = _4450.y;\n    _6326.z = _4450.z;\n    base_t = _6326;\n    vec4 _4464 = (_6326 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6142 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4498 = fa_tex_fix(param_6, param_7);\n        vec3 _4501 = (_4498 * 2.0) - vec3(1.0);\n        vec2 _4506 = _4501.xy * fa_mesh_fs_params[6].x;\n        vec3 _6334 = _4501;\n        _6334.x = _4506.x;\n        _6334.y = _4506.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6334;\n        _6142 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4536 = fa_tex_fix(param_12, param_13);\n    vec4 _6337 = mrt;\n    _6337.x = _4536.x;\n    _6337.y = _4536.y;\n    _6337.z = _4536.z;\n    mrt = _6337;\n    vec4 _4566 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4566.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4577 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4609 = fa_tex_fix(param_20, param_21);\n    float _6147 = fa_mesh_fs_params[20].x;\n    float _6148 = fa_mesh_fs_params[20].y;\n    float _6151 = fa_mesh_fs_params[20].z;\n    float _6150 = fa_mesh_fs_params[21].w;\n    float _6153 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6147 *= _4577.y;\n            _6148 *= _4577.z;\n            _6150 *= _4566.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6151 *= mrt.x;\n            _6153 *= mrt.w;\n        }\n    }\n    return Surface(_4464.xyz, _4464.w, _6142, clamp(fa_mesh_fs_params[5].x * _4536.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4536.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4577.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4609), _6147, _6148, fa_mesh_fs_params[21].xyz, _6150, _6151, fa_mesh_fs_params[20].w, _6153, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1580 = rect.zw - rect.xy;\n    vec2 _1584 = _1580 * atlas;\n    vec2 _1588 = ddx * _1584;\n    vec2 _1592 = ddy * _1584;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1580), clamp(0.5 * log2(max(max(dot(_1588, _1588), dot(_1592, _1592)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1625 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1632;\n    if (!_1625)\n    {\n        _1632 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1632 = _1625;\n    }\n    if (_1632)\n    {\n        return;\n    }\n    vec3 _1638 = dFdx(world_pos);\n    vec3 _1641 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1645 = fa_cluster_texel(param);\n    int _1649 = int(_1645.w);\n    if (_1649 < 1)\n    {\n        return;\n    }\n    int _1659 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1659;\n    vec4 _1663 = fa_light_texel(param_1);\n    vec2 _1666 = _1663.yz;\n    int _1670 = int(_1663.w);\n    int param_2 = _1659 + 1;\n    vec4 _1675 = fa_light_texel(param_2);\n    float _1676 = _1675.x;\n    int _1682 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1686 = int(_1645.z);\n    vec3 _1951;\n    for (int k = 0; k < _1649; k++)\n    {\n        int _1699 = _1686 + k;\n        int param_3 = _1670 + (_1699 >> 2);\n        int _1716 = (_1659 + 2) + (int(fa_light_texel(param_3)[_1699 & 3]) * 7);\n        int param_4 = _1716 + 6;\n        vec4 _1721 = fa_light_texel(param_4);\n        if (((int(_1721.w + 0.5) >> _1682) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1716;\n        vec4 _1736 = fa_light_texel(param_5);\n        int param_6 = _1716 + 1;\n        vec4 _1741 = fa_light_texel(param_6);\n        int param_7 = _1716 + 2;\n        vec4 _1746 = fa_light_texel(param_7);\n        vec3 _1749 = _1736.xyz;\n        float _1754 = dot(_1749, world_pos) + _1736.w;\n        vec3 _1756 = _1741.xyz;\n        float _1761 = dot(_1756, world_pos) + _1741.w;\n        vec3 _1763 = _1746.xyz;\n        float _1768 = dot(_1763, world_pos) + _1746.w;\n        bool _1773 = abs(_1754) > 0.5;\n        bool _1781;\n        if (!_1773)\n        {\n            _1781 = abs(_1761) > 0.5;\n        }\n        else\n        {\n            _1781 = _1773;\n        }\n        bool _1789;\n        if (!_1781)\n        {\n            _1789 = abs(_1768) > 0.5;\n        }\n        else\n        {\n            _1789 = _1781;\n        }\n        if (_1789)\n        {\n            continue;\n        }\n        float _1804 = clamp(dot(geo_normal, normalize(_1763)) * _1721.z, 0.0, 1.0);\n        if (_1804 <= 0.0)\n        {\n            continue;\n        }\n        float _1824 = (clamp((0.5 - abs(_1768)) * 10.0, 0.0, 1.0) * _1804) * _1721.x;\n        vec2 _1832 = vec2(_1754 + 0.5, 0.5 - _1761);\n        vec2 _1842 = vec2(dot(_1749, _1638), dot(_1756, _1638));\n        vec2 _1852 = vec2(dot(_1749, _1641), dot(_1756, _1641));\n        int param_8 = _1716 + 5;\n        vec4 _1857 = fa_light_texel(param_8);\n        int param_9 = _1716 + 3;\n        vec4 _1862 = fa_light_texel(param_9);\n        int param_10 = _1716 + 4;\n        vec4 _1867 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1857.xyz;\n        bool _1877 = _1862.z > _1862.x;\n        if (_1877)\n        {\n            vec4 param_11 = _1862;\n            vec2 param_12 = _1832;\n            vec2 param_13 = _1666;\n            vec2 param_14 = _1842;\n            vec2 param_15 = _1852;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1676 > 0.5) && (_1676 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1903 = fa_dc_to_linear(param_16);\n                vec4 _6230 = tx;\n                _6230.x = _1903.x;\n                _6230.y = _1903.y;\n                _6230.z = _1903.z;\n                tx = _6230;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1824 * tex_a) * _1857.w, 0.0, 1.0)));\n        if (_1867.z > _1867.x)\n        {\n            vec4 param_17 = _1867;\n            vec2 param_18 = _1832;\n            vec2 param_19 = _1666;\n            vec2 param_20 = _1842;\n            vec2 param_21 = _1852;\n            vec4 _1947 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1676 > 1.5)\n            {\n                vec3 param_22 = _1947.xyz;\n                vec3 _1957 = fa_dc_to_srgb(param_22);\n                _1951 = _1957;\n            }\n            else\n            {\n                _1951 = _1947.xyz;\n            }\n            vec3 _1966 = (_1951 * 2.0) - vec3(1.0);\n            vec2 _1971 = _1966.xy * _1721.y;\n            vec3 _1993 = (normalize(_1749) * _1971.x) + (normalize(_1756) * _1971.y);\n            vec3 _1996 = normalize(normal);\n            normal = normalize(mix(_1996, normalize((_1996 * max(_1966.z, 0.0500000007450580596923828125)) + (_1993 - (_1996 * dot(_1996, _1993)))), vec3(clamp(_1824 * (_1877 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3668 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3668;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3777 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3783 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3777 > 0.0005000000237487256526947021484375)\n    {\n        if (_3783)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3777;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3777;\n        }\n    }\n    bool _3835 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3835)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3866 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3866)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3783 || _3835) || _3866)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3688 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3691 = _3688.x;\n    float _3693 = _3688.z;\n    vec2 e = vec2(_3691, _3693);\n    if (_3688.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3693)) * ((_3691 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3691)) * ((_3693 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _4723 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _4728 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _4733 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _4738 = fa_light_texel(param_3);\n    bool _4741 = _4738.z < 0.5;\n    bool _4749;\n    if (!_4741)\n    {\n        _4749 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _4749 = _4741;\n    }\n    if (_4749)\n    {\n        return vec3(0.0);\n    }\n    float _4756 = max(_4723.w, 9.9999997473787516355514526367188e-05);\n    vec3 _4759 = _4728.xyz;\n    vec3 _4763 = _4723.xyz;\n    vec3 _4767 = (fa_world_pos - _4763) / vec3(_4756);\n    vec3 _4776 = min(_4767 + vec3(0.5), (_4759 - vec3(0.5)) - _4767);\n    float _4785 = min(_4776.x, min(_4776.y, _4776.z));\n    if (!(_4785 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4800 = _4759 - vec3(1.0);\n    vec3 _4801 = clamp(_4767, vec3(0.0), _4800);\n    vec3 _4809 = min(floor(_4801), max(_4759 - vec3(2.0), vec3(0.0)));\n    vec3 _4813 = _4801 - _4809;\n    vec3 _4825 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _4756));\n    int _4830 = int(_4733.y + 0.5);\n    float _4835 = 0.3257350027561187744140625 * n.y;\n    float _4839 = 0.3257350027561187744140625 * n.z;\n    float _4843 = 0.3257350027561187744140625 * n.x;\n    float _4850 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _4857 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _4866 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _4873 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _4886 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _4893 = 8 + int(_4738.w);\n    float _4920;\n    float _4933;\n    float _4947;\n    for (int k = 0; k < _4893; k++)\n    {\n        float _4906 = float(k & 1);\n        float _4910 = float((k >> 1) & 1);\n        float _4914 = float((k >> 2) & 1);\n        if (_4906 > 0.5)\n        {\n            _4920 = _4813.x;\n        }\n        else\n        {\n            _4920 = 1.0 - _4813.x;\n        }\n        if (_4910 > 0.5)\n        {\n            _4933 = _4813.y;\n        }\n        else\n        {\n            _4933 = 1.0 - _4813.y;\n        }\n        if (_4914 > 0.5)\n        {\n            _4947 = _4813.z;\n        }\n        else\n        {\n            _4947 = 1.0 - _4813.z;\n        }\n        float _4957 = (_4920 * _4933) * _4947;\n        if (!(_4957 > 0.0))\n        {\n            continue;\n        }\n        vec3 _4970 = min(_4809 + vec3(_4906, _4910, _4914), _4800);\n        int _4990 = int(((_4733.x + _4970.x) + (_4728.x * (_4970.y + (_4728.y * _4970.z)))) + 0.5);\n        vec2 _5005 = vec2(float(_4990 % _4830) * 10.0, 1024.0 + (float(_4990 / _4830) * 11.0));\n        vec2 param_4 = _5005 + vec2(9.5, 10.5);\n        vec4 _5013 = fa_gi_fetch(param_4);\n        bool _5016 = _5013.y < 0.5;\n        bool _5025;\n        if (!_5016)\n        {\n            _5025 = _5013.x > _4738.y;\n        }\n        else\n        {\n            _5025 = _5016;\n        }\n        if (_5025)\n        {\n            continue;\n        }\n        vec3 _5037 = _4825 - (_4763 + (_4970 * _4756));\n        float _5040 = length(_5037);\n        vec3 _5046 = _5037 / vec3(max(_5040, 9.9999997473787516355514526367188e-05));\n        float _5056 = max(9.9999997473787516355514526367188e-05, (dot(-_5046, n) + 1.0) * 0.5);\n        float w = _4957 * (_5056 * _5056);\n        vec3 param_5 = _5046;\n        vec2 param_6 = (_5005 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _5076 = fa_gi_fetch(param_6);\n        float _5083 = _5040 / max(_4733.z, 9.9999997473787516355514526367188e-05);\n        float _5086 = _5076.x;\n        if (_5083 > _5086)\n        {\n            float _5099 = max(_5076.y - (_5086 * _5086), 0.0);\n            float _5104 = _5083 - _5086;\n            float _5113 = _5099 / max(_5099 + (_5104 * _5104), 9.9999999600419720025001879548654e-13);\n            w *= ((_5113 * _5113) * _5113);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _5005 + vec2(0.5, 10.5);\n        vec2 param_8 = _5005 + vec2(1.5, 10.5);\n        vec2 param_9 = _5005 + vec2(2.5, 10.5);\n        vec2 param_10 = _5005 + vec2(3.5, 10.5);\n        vec2 param_11 = _5005 + vec2(4.5, 10.5);\n        vec2 param_12 = _5005 + vec2(5.5, 10.5);\n        vec2 param_13 = _5005 + vec2(6.5, 10.5);\n        vec2 param_14 = _5005 + vec2(7.5, 10.5);\n        vec2 param_15 = _5005 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _4835)) + (fa_gi_fetch(param_9).xyz * _4839)) + (fa_gi_fetch(param_10).xyz * _4843)) + (fa_gi_fetch(param_11).xyz * _4850)) + (fa_gi_fetch(param_12).xyz * _4857)) + (fa_gi_fetch(param_13).xyz * _4866)) + (fa_gi_fetch(param_14).xyz * _4873)) + (fa_gi_fetch(param_15).xyz * _4886)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_4785 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _5241;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _5241 = _4738.x;\n    }\n    else\n    {\n        _5241 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_4733.w * _5241);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _5265 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _5270 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _5275 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _5275) && (k < 8); k++)\n    {\n        int param = _5270 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _5265;\n        vec3 _5300 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5305 = param_3 * left;\n        acc += (_5300 * _5305);\n        left -= _5305;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _5334 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5334;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _5376 = vec4(fa_world_pos, 1.0);\n        vec2 _5395 = vec2(dot(fa_mesh_fs_params[26], _5376), dot(fa_mesh_fs_params[27], _5376)) / vec2(max(dot(fa_mesh_fs_params[28], _5376), 9.9999997473787516355514526367188e-05));\n        float _5404;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5404 = (_5395.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5404 = 0.5 - (_5395.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_5395.x * 0.5) + 0.5, _5404) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4175;\n    if (fa_lm.z > 0.5)\n    {\n        _4175 = 0.0;\n    }\n    else\n    {\n        _4175 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4186 = _4175 < 1.0;\n    bool _4192;\n    if (_4186)\n    {\n        int param = li;\n        _4192 = fa_light_baked(param);\n    }\n    else\n    {\n        _4192 = _4186;\n    }\n    return _4192 ? _4175 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _599 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _612 = (c - (ru * hx)) - p;\n        vec3 _618 = ru * (2.0 * hx);\n        float _624 = max(dot(_618, _618), 9.9999999392252902907785028219223e-09);\n        float _628 = dot(_612, _618);\n        float t = clamp((-_628) / _624, 0.0, 1.0);\n        if (_599)\n        {\n            float _643 = dot(r, _618);\n            float _649 = _624 - (_643 * _643);\n            if (abs(_649) > (9.9999997473787516355514526367188e-06 * _624))\n            {\n                t = clamp(((dot(r, _612) * _643) - _628) / _649, 0.0, 1.0);\n            }\n        }\n        return (p + _612) + (_618 * t);\n    }\n    vec3 q = p;\n    float _681 = dot(r, axis);\n    bool _689;\n    if (_599)\n    {\n        _689 = abs(_681) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _689 = _599;\n    }\n    if (_689)\n    {\n        float _699 = dot(c - p, axis) / _681;\n        if (_699 > 0.0)\n        {\n            q = p + (r * _699);\n        }\n    }\n    vec3 _712 = q - c;\n    vec2 xy = vec2(dot(_712, ru), dot(_712, uu));\n    if (shape > 0.5)\n    {\n        float _727 = length(xy);\n        if (_727 > hx)\n        {\n            xy *= (hx / _727);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _519 = dot(d, right);\n    float _523 = dot(d, up);\n    float _534;\n    if (((_519 * _519) + (_523 * _523)) > 1.0000000133514319600180897396058e-10)\n    {\n        _534 = atan(_523, _519) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _534 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_534 - floor(_534)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _369 = abs(d);\n    float _371 = _369.x;\n    float _373 = _369.y;\n    bool _374 = _371 >= _373;\n    bool _382;\n    if (_374)\n    {\n        _382 = _371 >= _369.z;\n    }\n    else\n    {\n        _382 = _374;\n    }\n    int _383;\n    if (_382)\n    {\n        _383 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _398;\n        if (_373 >= _369.z)\n        {\n            _398 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _398 = (d.z > 0.0) ? 4 : 5;\n        }\n        _383 = _398;\n    }\n    return _383;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _765 = fa_light_base(param);\n    bool _769 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _765;\n    vec4 _773 = fa_light_texel(param_1);\n    int param_2 = _765 + 1;\n    vec4 _778 = fa_light_texel(param_2);\n    float _781 = _778.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _793 = _769 && (_781 > 2.5);\n    fa_light_is_area = _793;\n    bool _795 = _781 < 0.5;\n    vec3 l;\n    if (_795)\n    {\n        l = normalize(_773.xyz);\n        if (_769)\n        {\n            int param_3 = _765 + 6;\n            vec4 _809 = fa_light_texel(param_3);\n            if (_809.z > 0.5)\n            {\n                int param_4 = _765 + 4;\n                vec4 _819 = fa_light_texel(param_4);\n                int param_5 = _765 + 5;\n                vec4 _824 = fa_light_texel(param_5);\n                vec2 param_6 = _809.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _819.xyz) * _819.w, (-dot(world_pos, _824.xyz)) * _824.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _854 = _773.xyz;\n        vec3 _856 = _854 - world_pos;\n        vec3 to_light = _856;\n        float _859 = length(_856);\n        float reach = _859;\n        bool front = true;\n        if (_793)\n        {\n            int param_8 = _765 + 7;\n            reach = max(_859 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _765 + 4;\n            vec4 _883 = fa_light_texel(param_9);\n            int param_10 = _765 + 5;\n            vec4 _888 = fa_light_texel(param_10);\n            int param_11 = _765 + 6;\n            vec4 _893 = fa_light_texel(param_11);\n            float _894 = _893.w;\n            int param_12 = _765 + 2;\n            vec3 _901 = normalize(fa_light_texel(param_12).xyz);\n            bool _903 = _894 > 1.5;\n            bool _911;\n            if (!_903)\n            {\n                _911 = dot(_901, to_light) < 0.0;\n            }\n            else\n            {\n                _911 = _903;\n            }\n            front = _911;\n            vec3 r = vec3(0.0);\n            vec3 _920 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _924 = dot(n, n) > 0.5;\n            bool _932;\n            if (_924)\n            {\n                _932 = dot(_920, _920) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _932 = _924;\n            }\n            if (_932)\n            {\n                r = reflect(-normalize(_920), normalize(n));\n            }\n            vec3 param_13 = _854;\n            vec3 param_14 = _901;\n            vec3 param_15 = _883.xyz;\n            vec3 param_16 = _888.xyz;\n            float param_17 = _883.w;\n            float param_18 = _888.w;\n            float param_19 = _894;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _968 = length(to_light);\n        dist = _968;\n        l = to_light / vec3(max(_968, 9.9999997473787516355514526367188e-05));\n        float _982 = reach / max(_773.w, 0.001000000047497451305389404296875);\n        float _988 = clamp(1.0 - (_982 * _982), 0.0, 1.0);\n        float _990;\n        if (front)\n        {\n            _990 = _988 * _988;\n        }\n        else\n        {\n            _990 = 0.0;\n        }\n        atten = _990;\n        bool _1001 = _781 < 2.5;\n        if ((_781 > 1.5) && _1001)\n        {\n            int param_22 = _765 + 2;\n            vec4 _1009 = fa_light_texel(param_22);\n            float _1019 = _1009.w;\n            int param_23 = _765 + 3;\n            vec4 _1024 = fa_light_texel(param_23);\n            float _1025 = _1024.x;\n            float cos_inner = _1025;\n            if (_1025 > 1.5)\n            {\n                cos_inner = mix(_1019, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1019, cos_inner, dot(-l, normalize(_1009.xyz)));\n        }\n        if (_769 && (_781 < 1.5))\n        {\n            int param_24 = _765 + 6;\n            vec4 _1049 = fa_light_texel(param_24);\n            if (_1049.z > 0.5)\n            {\n                vec3 _1057 = -to_light;\n                int param_25 = _765 + 4;\n                int param_26 = _765 + 5;\n                vec3 _1071 = fa_light_texel(param_25).xyz;\n                vec3 _1075 = fa_light_texel(param_26).xyz;\n                vec3 _1084 = vec3(dot(_1057, _1071), dot(_1057, _1075), dot(_1057, cross(_1071, _1075)));\n                vec3 param_27 = _1084;\n                int _1088 = fa_cube_face(param_27);\n                int param_28 = _1088;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1115 = vec2(dot(_1084, cross(param_29, param_30)), dot(_1084, param_30)) / vec2(max(dot(_1084, param_29), 9.9999997473787516355514526367188e-05));\n                int _1119 = _1088 / 3;\n                vec2 param_31 = _1049.xy + (vec2(float(_1088 - (_1119 * 3)), float(_1119)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1115.x), 0.5 - (0.5 * _1115.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _765 + 7;\n            vec4 _1149 = fa_light_texel(param_33);\n            if (_1149.z > 0.5)\n            {\n                int param_34 = _765 + 2;\n                int param_35 = _765 + 4;\n                int param_36 = _765 + 5;\n                vec2 param_37 = _1149.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_769 && _1001)\n            {\n                int param_42 = _765 + 6;\n                vec4 _1196 = fa_light_texel(param_42);\n                int param_43 = _765 + 7;\n                vec4 _1201 = fa_light_texel(param_43);\n                bool _1204 = _1196.z > 0.5;\n                bool _1211;\n                if (!_1204)\n                {\n                    _1211 = _1201.z > 0.5;\n                }\n                else\n                {\n                    _1211 = _1204;\n                }\n                if (_1211)\n                {\n                    int param_44 = _765 + 2;\n                    vec4 _1218 = fa_light_texel(param_44);\n                    vec3 _1222 = normalize(_1218.xyz);\n                    int param_45 = _765 + 4;\n                    vec4 _1227 = fa_light_texel(param_45);\n                    int param_46 = _765 + 5;\n                    vec4 _1232 = fa_light_texel(param_46);\n                    if (_1204)\n                    {\n                        vec3 _1240 = -to_light;\n                        float _1247 = _1218.w;\n                        float _1263 = 0.5 / max(dot(_1240, _1222) * (sqrt(max(1.0 - (_1247 * _1247), 0.0)) / max(_1247, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1196.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1240, _1227.xyz) * _1263), 0.5 - (dot(_1240, _1232.xyz) * _1263));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1201.z > 0.5)\n                    {\n                        vec2 param_49 = _1201.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1222;\n                        vec3 param_52 = _1227.xyz;\n                        vec3 param_53 = _1232.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6096 = _778.xyz * atten;\n    if (_769)\n    {\n        _6096 *= fa_light_tint;\n    }\n    int _1331;\n    if (_795)\n    {\n        _1331 = 0;\n    }\n    else\n    {\n        _1331 = ((_781 > 1.5) && (_781 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6096, atten, 1.0, dist, _1331);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2120 = fa_shadow_depth(param, param_1);\n    float _2124;\n    if (conv.x < 0.5)\n    {\n        _2124 = _2120;\n    }\n    else\n    {\n        _2124 = (conv.y * conv.z) / (conv.z - (_2120 * (conv.z - conv.y)));\n    }\n    return _2124;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2170 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2176 = vec2(cos(_2170), sin(_2170));\n    vec2 dir = _2176;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2185;\n        if (k < 0.0)\n        {\n            _2185 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2185 = k;\n        }\n        float _2204 = clamp((_2185 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2223 = sqrt((float(i) + 0.5) * 0.0625) * _2204;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2223));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2237 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2237 < (zr - (_2223 * plane)))\n            {\n                sum += _2237;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2265 = sum / cnt;\n        float _2275;\n        if (k < 0.0)\n        {\n            _2275 = (-k) / max(_2265, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2275 = k;\n        }\n        radius = clamp(((max(zr - _2265, 0.0) * unit) * _2275) / texel_m, 1.5, 16.0);\n        dir = _2176;\n    }\n    float lit = 0.0;\n    int _2301 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2301; i_1++)\n    {\n        float _2320 = sqrt((float(i_1) + 0.5) / float(_2301)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2320));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2320 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2301);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2525 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2532;\n    if (!_2525)\n    {\n        _2532 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2532 = _2525;\n    }\n    if (_2532)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2545 = fa_light_texel(param);\n    float _2546 = _2545.x;\n    if (_2546 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2555 = int(_2546 + 0.5);\n    int param_1 = _2555;\n    vec4 _2559 = fa_light_texel(param_1);\n    int param_2 = _2555 + 1;\n    vec4 _2564 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2567 = _2559.y;\n    if (_2567 > 0.0)\n    {\n        float _2584 = 1.0 - smoothstep(0.75 * _2567, _2567, length(world - fa_shadows[27].xyz));\n        fade = _2584;\n        if (_2584 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2559.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2608 = (_2555 + 2) + (face * 6);\n    int param_4 = _2608;\n    int param_5 = _2608 + 1;\n    int param_6 = _2608 + 3;\n    vec4 _2622 = fa_light_texel(param_6);\n    int param_7 = _2608 + 4;\n    vec4 _2627 = fa_light_texel(param_7);\n    int param_8 = _2608 + 5;\n    vec4 _2632 = fa_light_texel(param_8);\n    float _2644 = _2632.x * max(dot(_2622, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2649 = clamp(dot(n, l), 0.0, 1.0);\n    float _2672 = clamp(dot(n, _2622.xyz), -1.0, 1.0);\n    float _2691 = min(sqrt(1.0 - (_2672 * _2672)) / max(abs(dot(n, world - lpos)) / max(dot(_2622, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2694 = _2564.y;\n    float _2696;\n    if (_2694 > 0.0)\n    {\n        _2696 = _2694;\n    }\n    else\n    {\n        _2696 = 1.5 * _2644;\n    }\n    vec4 _2716 = vec4(world + (n * (_2696 * sqrt(1.0 - (_2649 * _2649)))), 1.0);\n    float _2720 = dot(_2622, _2716);\n    float _2723 = _2632.y;\n    if (_2720 < _2723)\n    {\n        return 1.0;\n    }\n    vec2 _2738 = vec2(dot(fa_light_texel(param_4), _2716), dot(fa_light_texel(param_5), _2716)) / vec2(_2720);\n    float _2740 = _2738.x;\n    bool _2743 = _2740 < _2627.x;\n    bool _2752;\n    if (!_2743)\n    {\n        _2752 = _2740 > _2627.z;\n    }\n    else\n    {\n        _2752 = _2743;\n    }\n    bool _2761;\n    if (!_2752)\n    {\n        _2761 = _2738.y < _2627.y;\n    }\n    else\n    {\n        _2761 = _2752;\n    }\n    bool _2770;\n    if (!_2761)\n    {\n        _2770 = _2738.y > _2627.w;\n    }\n    else\n    {\n        _2770 = _2761;\n    }\n    if (_2770)\n    {\n        return 1.0;\n    }\n    float _2776 = _2564.x;\n    float _2778;\n    if (_2776 > 0.0)\n    {\n        _2778 = _2776;\n    }\n    else\n    {\n        _2778 = 1.5 * _2644;\n    }\n    vec2 param_9 = _2738;\n    vec4 param_10 = _2627;\n    float param_11 = _2720 - (_2778 * (1.0 + (0.5 * _2691)));\n    float param_12 = _2644;\n    float param_13 = 1.0;\n    float param_14 = _2632.z * 0.25;\n    float param_15 = (_2644 * min(_2691, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2723, _2632.z);\n    int param_17 = int(_2559.z + 0.5);\n    float param_18 = _2559.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3290 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3296;\n    if (_3290)\n    {\n        _3296 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3296 = _3290;\n    }\n    bool _3302;\n    if (_3296)\n    {\n        _3302 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3302 = _3296;\n    }\n    if (_3302)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3314 = fa_light_texel(param);\n        float _3315 = _3314.z;\n        if (_3315 > 0.5)\n        {\n            float _3328 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3331 = fwidth(_3328);\n            float _3335 = min(1.5 * _3331, 0.100000001490116119384765625 * _3328);\n            vec4 _3341 = vec4(world, 1.0);\n            float _3346 = dot(fa_mesh_fs_params[28], _3341);\n            if (_3346 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3363 = vec2(dot(fa_mesh_fs_params[26], _3341), dot(fa_mesh_fs_params[27], _3341)) / vec2(_3346);\n                float _3368 = (_3363.x * 0.5) + 0.5;\n                float _3372;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3372 = (_3363.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3372 = 0.5 - (_3363.y * 0.5);\n                }\n                bool _3388 = _3368 >= 0.0;\n                bool _3394;\n                if (_3388)\n                {\n                    _3394 = _3368 < 1.0;\n                }\n                else\n                {\n                    _3394 = _3388;\n                }\n                bool _3400;\n                if (_3394)\n                {\n                    _3400 = _3372 >= 0.0;\n                }\n                else\n                {\n                    _3400 = _3394;\n                }\n                bool _3406;\n                if (_3400)\n                {\n                    _3406 = _3372 < 1.0;\n                }\n                else\n                {\n                    _3406 = _3400;\n                }\n                if (_3406)\n                {\n                    ivec2 _3423 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3424 = clamp(ivec2(vec2(_3368, _3372) * fa_mesh_fs_params[24].zw), ivec2(0), _3423);\n                    ivec2 _3436;\n                    ivec2 _3442;\n                    ivec2 _3449;\n                    float _3500;\n                    float _3521;\n                    for (int k = 0; k < 5; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3436 = ivec2(0);\n                        }\n                        else\n                        {\n                            if (k == 1)\n                            {\n                                _3442 = ivec2(1, 0);\n                            }\n                            else\n                            {\n                                if (k == 2)\n                                {\n                                    _3449 = ivec2(-1, 0);\n                                }\n                                else\n                                {\n                                    bvec2 _3460 = bvec2(k == 3);\n                                    _3449 = ivec2(_3460.x ? ivec2(0, 1).x : ivec2(0, -1).x, _3460.y ? ivec2(0, 1).y : ivec2(0, -1).y);\n                                }\n                                _3442 = _3449;\n                            }\n                            _3436 = _3442;\n                        }\n                        vec4 _3477 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3424 + _3436, ivec2(0), _3423), 0);\n                        bool _3480 = _3477.w > 0.5;\n                        bool _3494;\n                        if (_3480)\n                        {\n                            _3494 = abs(_3328 - _3477.x) <= (((0.00200000009499490261077880859375 * _3328) + 0.00999999977648258209228515625) + _3335);\n                        }\n                        else\n                        {\n                            _3494 = _3480;\n                        }\n                        if (_3494)\n                        {\n                            if (_3315 < 1.5)\n                            {\n                                _3500 = 1.0;\n                            }\n                            else\n                            {\n                                _3500 = (_3315 < 2.5) ? 256.0 : 65536.0;\n                            }\n                            float _3517 = mod(floor(_3477.z / _3500), 256.0) * 0.0039215688593685626983642578125;\n                            if (fa_mesh_fs_params[25].z > 0.5)\n                            {\n                                int param_1 = li;\n                                vec3 param_2 = lpos;\n                                vec3 param_3 = world;\n                                vec3 param_4 = n;\n                                vec3 param_5 = l;\n                                _3521 = min(_3517, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                            }\n                            else\n                            {\n                                _3521 = _3517;\n                            }\n                            return _3521;\n                        }\n                    }\n                }\n            }\n            float _3546;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3546 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3546 = 1.0;\n            }\n            return _3546;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2063;\n    if (i == 0)\n    {\n        _2063 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2079;\n        if (i == 1)\n        {\n            _2079 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2087;\n            if (i == 2)\n            {\n                _2087 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2087 = fa_shadows[24].w;\n            }\n            _2079 = _2087;\n        }\n        _2063 = _2079;\n    }\n    return _2063;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2366 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2371 = clamp(dot(n, l), 0.0, 1.0);\n    float _2377 = sqrt(1.0 - (_2371 * _2371));\n    float _2385 = min(_2377 / max(_2371, 0.20000000298023223876953125), 4.0);\n    float _2390;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2390 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2390 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2415 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2390 * _2377)), 1.0);\n    float _2422 = _2415.x;\n    bool _2425 = _2422 < fa_shadows[ci * 1 + 16].x;\n    bool _2434;\n    if (!_2425)\n    {\n        _2434 = _2422 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2434 = _2425;\n    }\n    bool _2443;\n    if (!_2434)\n    {\n        _2443 = _2415.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2443 = _2434;\n    }\n    bool _2452;\n    if (!_2443)\n    {\n        _2452 = _2415.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2452 = _2443;\n    }\n    bool _2459;\n    if (!_2452)\n    {\n        _2459 = _2415.z > 1.0;\n    }\n    else\n    {\n        _2459 = _2452;\n    }\n    if (_2459)\n    {\n        return -1.0;\n    }\n    float _2467;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2467 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2467 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2415.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2415.z - ((_2467 * (1.0 + (0.5 * _2385))) / _2366);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2366;\n    float param_5 = _2366 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2385, 3.0)) * 0.5) / _2366;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2845 = int(fa_shadows[25].x + 0.5);\n    if (_2845 < 1)\n    {\n        return 1.0;\n    }\n    float _2860 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2845 - 1;\n    if (_2860 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2872 = _2845 > 1;\n    bool _2879;\n    if (_2872)\n    {\n        _2879 = _2860 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2879 = _2872;\n    }\n    if (_2879)\n    {\n        ci = 1;\n    }\n    bool _2883 = _2845 > 2;\n    bool _2890;\n    if (_2883)\n    {\n        _2890 = _2860 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2890 = _2883;\n    }\n    if (_2890)\n    {\n        ci = 2;\n    }\n    bool _2894 = _2845 > 3;\n    bool _2901;\n    if (_2894)\n    {\n        _2901 = _2860 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2901 = _2894;\n    }\n    if (_2901)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2912 = min(_2845, 4);\n    float _2953;\n    for (int c = ci; c < _2912; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2932 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2932;\n            break;\n        }\n        if (_2932 < 0.0)\n        {\n            continue;\n        }\n        s = _2932;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2953 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2953 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _2972 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2953, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2860 - (fa_shadow_split_at(param_7) - _2972)) / _2972, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3004;\n        if ((ci + 1) < _2845)\n        {\n            _3004 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3004 = 1.0;\n        }\n        s = mix(s, _3004, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3109 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3115;\n    if (_3109)\n    {\n        _3115 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3115 = _3109;\n    }\n    if (_3115)\n    {\n        float _3129 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        float _3132 = fwidth(_3129);\n        vec4 _3142 = vec4(fa_world_pos, 1.0);\n        float _3148 = dot(fa_mesh_fs_params[28], _3142);\n        if (_3148 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3167 = vec2(dot(fa_mesh_fs_params[26], _3142), dot(fa_mesh_fs_params[27], _3142)) / vec2(_3148);\n            float _3172 = (_3167.x * 0.5) + 0.5;\n            float _3176;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3176 = (_3167.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3176 = 0.5 - (_3167.y * 0.5);\n            }\n            bool _3192 = _3172 >= 0.0;\n            bool _3198;\n            if (_3192)\n            {\n                _3198 = _3172 < 1.0;\n            }\n            else\n            {\n                _3198 = _3192;\n            }\n            bool _3204;\n            if (_3198)\n            {\n                _3204 = _3176 >= 0.0;\n            }\n            else\n            {\n                _3204 = _3198;\n            }\n            bool _3210;\n            if (_3204)\n            {\n                _3210 = _3176 < 1.0;\n            }\n            else\n            {\n                _3210 = _3204;\n            }\n            if (_3210)\n            {\n                vec4 _3236 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3172, _3176) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3239 = _3236.w > 0.5;\n                bool _3255;\n                if (_3239)\n                {\n                    _3255 = abs(_3129 - _3236.x) <= (((0.00200000009499490261077880859375 * _3129) + 0.00999999977648258209228515625) + min(1.5 * _3132, 0.100000001490116119384765625 * _3129));\n                }\n                else\n                {\n                    _3255 = _3239;\n                }\n                if (_3255)\n                {\n                    float _3261;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3261 = min(_3236.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3261 = _3236.y;\n                    }\n                    return _3261;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3917 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3924;\n    if (!_3917)\n    {\n        _3924 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3924 = _3917;\n    }\n    if (_3924)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3937 = fa_light_texel(param);\n    float _3938 = _3937.y;\n    float len = _3938;\n    if (_3938 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3950 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3959 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3950);\n    if (_3959 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3965 = len;\n    float _3968 = min(_3965, 0.89999997615814208984375 * dist);\n    len = _3968;\n    float _3974 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3950);\n    float _3979 = _3974 + (0.5 * _3968);\n    vec3 _3985 = world + (gn * _3974);\n    float _3987 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4049;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4003 = (float(k) + _3987) * 0.083333335816860198974609375;\n        vec3 _4011 = _3985 + (l * (_4003 * len));\n        vec4 _4017 = vec4(_4011, 1.0);\n        float _4022 = dot(fa_mesh_fs_params[28], _4017);\n        if (_4022 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4040 = vec2(dot(fa_mesh_fs_params[26], _4017), dot(fa_mesh_fs_params[27], _4017)) / vec2(_4022);\n        float _4044 = _4040.x * 0.5;\n        float _4045 = _4044 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4049 = (_4040.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4049 = 0.5 - (_4040.y * 0.5);\n        }\n        bool _4065 = _4045 < 0.0;\n        bool _4072;\n        if (!_4065)\n        {\n            _4072 = _4045 >= 1.0;\n        }\n        else\n        {\n            _4072 = _4065;\n        }\n        bool _4079;\n        if (!_4072)\n        {\n            _4079 = _4049 < 0.0;\n        }\n        else\n        {\n            _4079 = _4072;\n        }\n        bool _4086;\n        if (!_4079)\n        {\n            _4086 = _4049 >= 1.0;\n        }\n        else\n        {\n            _4086 = _4079;\n        }\n        if (_4086)\n        {\n            break;\n        }\n        vec4 _4110 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4045, _4049) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4110.w < 0.5)\n        {\n            continue;\n        }\n        float _4128 = (dot(fa_mesh_fs_params[29].xyz, _4011) + fa_mesh_fs_params[29].w) - _4110.x;\n        if ((_4128 > _3974) && (_4128 < _3979))\n        {\n            occ = max(occ, (1.0 - (_4003 * _4003)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4045, 0.5 - _4044), min(_4049, 1.0 - _4049))));\n        }\n    }\n    return 1.0 - (occ * _3959);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4231 = fa_baked_keep(param);\n    if (_4231 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4257 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6122 = _4257.color;\n    float _6123 = _4257.attenuation;\n    float _6124 = _4257.shadow;\n    bool _4260 = _4257.type == 0;\n    if (_4260 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4257.direction;\n        float _4271 = fa_shadow_factor(param_5, param_6);\n        _6124 = _4271;\n        _6122 *= _4271;\n    }\n    else\n    {\n        bool _4282 = _4257.type != 0;\n        bool _4288;\n        if (_4282)\n        {\n            _4288 = _6123 > 0.0;\n        }\n        else\n        {\n            _4288 = _4282;\n        }\n        if (_4288)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4257.direction;\n            float _4307 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6124 = _4307;\n            _6122 *= _4307;\n        }\n    }\n    bool _4317 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4323;\n    if (_4317)\n    {\n        _4323 = _6123 > 0.0;\n    }\n    else\n    {\n        _4323 = _4317;\n    }\n    if (_4323)\n    {\n        float _4330;\n        if (_4260)\n        {\n            _4330 = 1000000000.0;\n        }\n        else\n        {\n            _4330 = _4257._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4257.direction;\n        float param_18 = _4330;\n        float _4348 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6124 *= _4348;\n        _6122 *= _4348;\n    }\n    float _4361 = _6123;\n    float _4362 = _4361 * _4231;\n    _6123 = _4362;\n    vec3 _4366 = _6122;\n    vec3 _4367 = _4366 * _4231;\n    _6122 = _4367;\n    return LightSample(_4257.direction, _4367, _4362, _6124, _4257._distance, _4257.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3032 = int(fa_shadows[25].x + 0.5);\n    float _3042 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3047 = _3032 > 0;\n    bool _3056;\n    if (_3047)\n    {\n        int param = _3032 - 1;\n        _3056 = _3042 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3056 = _3047;\n    }\n    if (_3056)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3062 = _3032 > 1;\n        bool _3069;\n        if (_3062)\n        {\n            _3069 = _3042 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3069 = _3062;\n        }\n        if (_3069)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3075 = _3032 > 2;\n        bool _3082;\n        if (_3075)\n        {\n            _3082 = _3042 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3082 = _3075;\n        }\n        if (_3082)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3088 = _3032 > 3;\n        bool _3095;\n        if (_3088)\n        {\n            _3095 = _3042 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3095 = _3088;\n        }\n        if (_3095)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5943 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5943 = -_5943;\n    }\n    vec3 _5517 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5943, fa_world_tangent, fa_uv, fa_vertex_color, _5517, gl_FrontFacing);\n    Surface _5525 = fa_standard_surface(param_1);\n    vec3 _5974 = _5525.albedo;\n    float _5975 = _5525.alpha;\n    vec3 _5976 = _5525.normal;\n    float _5977 = _5525.metallic;\n    float _5978 = _5525.roughness;\n    float _5979 = _5525.occlusion;\n    vec3 _5980 = _5525.emission;\n    float _5981 = _5525.clearcoat;\n    float _5982 = _5525.clearcoat_roughness;\n    vec3 _5983 = _5525.sheen_color;\n    float _5984 = _5525.sheen_roughness;\n    float _5985 = _5525.anisotropy;\n    float _5986 = _5525.anisotropy_rotation;\n    float _5987 = _5525.specular;\n    float _5988 = _5525.ior;\n    vec3 _5989 = _5525.specular_color;\n    float _5990 = _5525.transmission;\n    float _5991 = _5525.thickness;\n    vec3 _5992 = _5525.attenuation_color;\n    float _5993 = _5525.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5943, fa_world_tangent, fa_uv, fa_vertex_color, _5517, gl_FrontFacing);\n    Surface param_3 = _5525;\n    surface(param_2, param_3);\n    _5974 = param_3.albedo;\n    _5975 = param_3.alpha;\n    _5976 = param_3.normal;\n    _5977 = param_3.metallic;\n    _5978 = param_3.roughness;\n    _5979 = param_3.occlusion;\n    _5980 = param_3.emission;\n    _5981 = param_3.clearcoat;\n    _5982 = param_3.clearcoat_roughness;\n    _5983 = param_3.sheen_color;\n    _5984 = param_3.sheen_roughness;\n    _5985 = param_3.anisotropy;\n    _5986 = param_3.anisotropy_rotation;\n    _5987 = param_3.specular;\n    _5988 = param_3.ior;\n    _5989 = param_3.specular_color;\n    _5990 = param_3.transmission;\n    _5991 = param_3.thickness;\n    _5992 = param_3.attenuation_color;\n    _5993 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5943;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5974 = param_6;\n    _5976 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5974;\n    }\n    else\n    {\n        vec3 _5564 = _5976;\n        vec3 _5565 = normalize(_5564);\n        _5976 = _5565;\n        vec3 param_8 = _5565;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _5974) * _5979;\n        int _5584 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5584; ln++)\n        {\n            int param_9 = ln;\n            int _5597 = fa_cl_light(param_9);\n            int param_10 = _5597;\n            if (fa_baked_keep(param_10) <= 0.0)\n            {\n                continue;\n            }\n            int param_11 = _5597;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _5943;\n            LightSample _5613 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _5943, fa_world_tangent, fa_uv, fa_vertex_color, _5517, gl_FrontFacing);\n            Surface param_15 = Surface(_5974, _5975, _5976, _5977, _5978, _5979, _5980, _5981, _5982, _5983, _5984, _5985, _5986, _5987, _5988, _5989, _5990, _5991, _5992, _5993);\n            LightSample param_16 = _5613;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _5628 = result;\n    vec3 _5629 = _5628 + _5980;\n    result = _5629;\n    vec3 param_17 = _5629;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _5638 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5645;\n    if (!_5638)\n    {\n        _5645 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5645 = _5638;\n    }\n    if (_5645)\n    {\n        vec3 _5654 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5660 = dot(_5654, fa_mesh_fs_params[9].xyz);\n        bool _5664 = fa_mesh_fs_params[9].w > 0.5;\n        float _5665;\n        if (_5664)\n        {\n            _5665 = _5660;\n        }\n        else\n        {\n            _5665 = length(_5654);\n        }\n        float _5677 = _5665 - fa_mesh_fs_params[8].x;\n        if (_5677 > 0.0)\n        {\n            float _5686 = fa_mesh_fs_params[7].w * _5677;\n            float tau = _5686 * _5686;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5702;\n                if (_5664)\n                {\n                    _5702 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5660);\n                }\n                else\n                {\n                    _5702 = fa_mesh_fs_params[0].y;\n                }\n                float _5723 = mix(_5702, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5665, 0.0, 1.0));\n                float _5727 = fa_world_pos.y - _5723;\n                float _5732 = _5723 - fa_mesh_fs_params[8].z;\n                float _5737 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5740 = _5732 <= 0.0;\n                bool _5741 = !_5740;\n                bool _5747;\n                if (_5741)\n                {\n                    _5747 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5747 = _5740;\n                }\n                float _5748;\n                if (_5747)\n                {\n                    _5748 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5748 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5732, 80.0));\n                }\n                bool _5775;\n                if (_5741)\n                {\n                    _5775 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5775 = _5740;\n                }\n                float _5776;\n                if (_5775)\n                {\n                    _5776 = fa_mesh_fs_params[8].y * _5732;\n                }\n                else\n                {\n                    _5776 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5732, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5801 = _5737 <= 0.0;\n                bool _5808;\n                if (!_5801)\n                {\n                    _5808 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5808 = _5801;\n                }\n                float _5809;\n                if (_5808)\n                {\n                    _5809 = fa_mesh_fs_params[8].y * _5737;\n                }\n                else\n                {\n                    _5809 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5737, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5836;\n                if (abs(_5727) < 0.001000000047497451305389404296875)\n                {\n                    _5836 = _5748;\n                }\n                else\n                {\n                    _5836 = (_5809 - _5776) / _5727;\n                }\n                tau += (_5677 * max(_5836, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5975);\n}\n\n",
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
            "inst_name": "_421",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1349 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1356;\n    if (!_1349)\n    {\n        _1356 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1356 = _1349;\n    }\n    bool _1364;\n    if (!_1356)\n    {\n        _1364 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1364 = _1356;\n    }\n    bool _1371;\n    if (!_1364)\n    {\n        _1371 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1371 = _1364;\n    }\n    bool _1378;\n    if (!_1371)\n    {\n        _1378 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1378 = _1371;\n    }\n    if (_1378)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1388 = vec4(world_pos, 1.0);\n    float _1394 = dot(fa_mesh_fs_params[16], _1388);\n    if (!(_1394 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1416 = vec2(dot(fa_mesh_fs_params[14], _1388), dot(fa_mesh_fs_params[15], _1388)) / vec2(_1394);\n    int _1420 = int(fa_mesh_fs_params[18].x);\n    int _1424 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1424) + clamp(int(floor(((_1416.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1424 - 1)) * _1420)) + clamp(int(floor(((_1416.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1420 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1500 = fa_cluster_texel(param);\n    return ivec2(int(_1500.x), int(_1500.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4205 = fa_cluster_lookup(param);\n    fa_cl_slot = _4205.x;\n    fa_cl_local = _4205.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4410 = fa_linear_to_srgb(param);\n        c = _4410;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4418 = fa_srgb_to_linear(param_1);\n            c = _4418;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _303;\n    if (i.front_facing)\n    {\n        _303 = i.world_normal;\n    }\n    else\n    {\n        _303 = -i.world_normal;\n    }\n    vec3 _327 = normalize(i.world_tangent.xyz - (_303 * dot(_303, i.world_tangent.xyz)));\n    vec3 _354 = normalize(((_327 * m.x) + ((cross(_303, _327) * i.world_tangent.w) * m.y)) + (_303 * m.z));\n    vec3 _357;\n    if (i.front_facing)\n    {\n        _357 = _354;\n    }\n    else\n    {\n        _357 = -_354;\n    }\n    return _357;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4450 = fa_tex_fix(param_2, param_3);\n    vec4 _6326 = base_t;\n    _6326.x = _4450.x;\n    _6326.y = _4450.y;\n    _6326.z = _4450.z;\n    base_t = _6326;\n    vec4 _4464 = (_6326 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6142 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4498 = fa_tex_fix(param_6, param_7);\n        vec3 _4501 = (_4498 * 2.0) - vec3(1.0);\n        vec2 _4506 = _4501.xy * fa_mesh_fs_params[6].x;\n        vec3 _6334 = _4501;\n        _6334.x = _4506.x;\n        _6334.y = _4506.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6334;\n        _6142 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4536 = fa_tex_fix(param_12, param_13);\n    vec4 _6337 = mrt;\n    _6337.x = _4536.x;\n    _6337.y = _4536.y;\n    _6337.z = _4536.z;\n    mrt = _6337;\n    vec4 _4566 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4566.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4577 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4609 = fa_tex_fix(param_20, param_21);\n    float _6147 = fa_mesh_fs_params[20].x;\n    float _6148 = fa_mesh_fs_params[20].y;\n    float _6151 = fa_mesh_fs_params[20].z;\n    float _6150 = fa_mesh_fs_params[21].w;\n    float _6153 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6147 *= _4577.y;\n            _6148 *= _4577.z;\n            _6150 *= _4566.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6151 *= mrt.x;\n            _6153 *= mrt.w;\n        }\n    }\n    return Surface(_4464.xyz, _4464.w, _6142, clamp(fa_mesh_fs_params[5].x * _4536.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4536.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4577.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4609), _6147, _6148, fa_mesh_fs_params[21].xyz, _6150, _6151, fa_mesh_fs_params[20].w, _6153, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1580 = rect.zw - rect.xy;\n    vec2 _1584 = _1580 * atlas;\n    vec2 _1588 = ddx * _1584;\n    vec2 _1592 = ddy * _1584;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1580), clamp(0.5 * log2(max(max(dot(_1588, _1588), dot(_1592, _1592)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1625 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1632;\n    if (!_1625)\n    {\n        _1632 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1632 = _1625;\n    }\n    if (_1632)\n    {\n        return;\n    }\n    vec3 _1638 = dFdx(world_pos);\n    vec3 _1641 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1645 = fa_cluster_texel(param);\n    int _1649 = int(_1645.w);\n    if (_1649 < 1)\n    {\n        return;\n    }\n    int _1659 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1659;\n    vec4 _1663 = fa_light_texel(param_1);\n    vec2 _1666 = _1663.yz;\n    int _1670 = int(_1663.w);\n    int param_2 = _1659 + 1;\n    vec4 _1675 = fa_light_texel(param_2);\n    float _1676 = _1675.x;\n    int _1682 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1686 = int(_1645.z);\n    vec3 _1951;\n    for (int k = 0; k < _1649; k++)\n    {\n        int _1699 = _1686 + k;\n        int param_3 = _1670 + (_1699 >> 2);\n        int _1716 = (_1659 + 2) + (int(fa_light_texel(param_3)[_1699 & 3]) * 7);\n        int param_4 = _1716 + 6;\n        vec4 _1721 = fa_light_texel(param_4);\n        if (((int(_1721.w + 0.5) >> _1682) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1716;\n        vec4 _1736 = fa_light_texel(param_5);\n        int param_6 = _1716 + 1;\n        vec4 _1741 = fa_light_texel(param_6);\n        int param_7 = _1716 + 2;\n        vec4 _1746 = fa_light_texel(param_7);\n        vec3 _1749 = _1736.xyz;\n        float _1754 = dot(_1749, world_pos) + _1736.w;\n        vec3 _1756 = _1741.xyz;\n        float _1761 = dot(_1756, world_pos) + _1741.w;\n        vec3 _1763 = _1746.xyz;\n        float _1768 = dot(_1763, world_pos) + _1746.w;\n        bool _1773 = abs(_1754) > 0.5;\n        bool _1781;\n        if (!_1773)\n        {\n            _1781 = abs(_1761) > 0.5;\n        }\n        else\n        {\n            _1781 = _1773;\n        }\n        bool _1789;\n        if (!_1781)\n        {\n            _1789 = abs(_1768) > 0.5;\n        }\n        else\n        {\n            _1789 = _1781;\n        }\n        if (_1789)\n        {\n            continue;\n        }\n        float _1804 = clamp(dot(geo_normal, normalize(_1763)) * _1721.z, 0.0, 1.0);\n        if (_1804 <= 0.0)\n        {\n            continue;\n        }\n        float _1824 = (clamp((0.5 - abs(_1768)) * 10.0, 0.0, 1.0) * _1804) * _1721.x;\n        vec2 _1832 = vec2(_1754 + 0.5, 0.5 - _1761);\n        vec2 _1842 = vec2(dot(_1749, _1638), dot(_1756, _1638));\n        vec2 _1852 = vec2(dot(_1749, _1641), dot(_1756, _1641));\n        int param_8 = _1716 + 5;\n        vec4 _1857 = fa_light_texel(param_8);\n        int param_9 = _1716 + 3;\n        vec4 _1862 = fa_light_texel(param_9);\n        int param_10 = _1716 + 4;\n        vec4 _1867 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1857.xyz;\n        bool _1877 = _1862.z > _1862.x;\n        if (_1877)\n        {\n            vec4 param_11 = _1862;\n            vec2 param_12 = _1832;\n            vec2 param_13 = _1666;\n            vec2 param_14 = _1842;\n            vec2 param_15 = _1852;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1676 > 0.5) && (_1676 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1903 = fa_dc_to_linear(param_16);\n                vec4 _6230 = tx;\n                _6230.x = _1903.x;\n                _6230.y = _1903.y;\n                _6230.z = _1903.z;\n                tx = _6230;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1824 * tex_a) * _1857.w, 0.0, 1.0)));\n        if (_1867.z > _1867.x)\n        {\n            vec4 param_17 = _1867;\n            vec2 param_18 = _1832;\n            vec2 param_19 = _1666;\n            vec2 param_20 = _1842;\n            vec2 param_21 = _1852;\n            vec4 _1947 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1676 > 1.5)\n            {\n                vec3 param_22 = _1947.xyz;\n                vec3 _1957 = fa_dc_to_srgb(param_22);\n                _1951 = _1957;\n            }\n            else\n            {\n                _1951 = _1947.xyz;\n            }\n            vec3 _1966 = (_1951 * 2.0) - vec3(1.0);\n            vec2 _1971 = _1966.xy * _1721.y;\n            vec3 _1993 = (normalize(_1749) * _1971.x) + (normalize(_1756) * _1971.y);\n            vec3 _1996 = normalize(normal);\n            normal = normalize(mix(_1996, normalize((_1996 * max(_1966.z, 0.0500000007450580596923828125)) + (_1993 - (_1996 * dot(_1996, _1993)))), vec3(clamp(_1824 * (_1877 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3668 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3668;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3777 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3783 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3777 > 0.0005000000237487256526947021484375)\n    {\n        if (_3783)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3777;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3777;\n        }\n    }\n    bool _3835 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3835)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3866 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3866)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3783 || _3835) || _3866)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3688 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3691 = _3688.x;\n    float _3693 = _3688.z;\n    vec2 e = vec2(_3691, _3693);\n    if (_3688.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3693)) * ((_3691 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3691)) * ((_3693 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _4723 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _4728 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _4733 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _4738 = fa_light_texel(param_3);\n    bool _4741 = _4738.z < 0.5;\n    bool _4749;\n    if (!_4741)\n    {\n        _4749 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _4749 = _4741;\n    }\n    if (_4749)\n    {\n        return vec3(0.0);\n    }\n    float _4756 = max(_4723.w, 9.9999997473787516355514526367188e-05);\n    vec3 _4759 = _4728.xyz;\n    vec3 _4763 = _4723.xyz;\n    vec3 _4767 = (fa_world_pos - _4763) / vec3(_4756);\n    vec3 _4776 = min(_4767 + vec3(0.5), (_4759 - vec3(0.5)) - _4767);\n    float _4785 = min(_4776.x, min(_4776.y, _4776.z));\n    if (!(_4785 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4800 = _4759 - vec3(1.0);\n    vec3 _4801 = clamp(_4767, vec3(0.0), _4800);\n    vec3 _4809 = min(floor(_4801), max(_4759 - vec3(2.0), vec3(0.0)));\n    vec3 _4813 = _4801 - _4809;\n    vec3 _4825 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _4756));\n    int _4830 = int(_4733.y + 0.5);\n    float _4835 = 0.3257350027561187744140625 * n.y;\n    float _4839 = 0.3257350027561187744140625 * n.z;\n    float _4843 = 0.3257350027561187744140625 * n.x;\n    float _4850 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _4857 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _4866 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _4873 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _4886 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _4893 = 8 + int(_4738.w);\n    float _4920;\n    float _4933;\n    float _4947;\n    for (int k = 0; k < _4893; k++)\n    {\n        float _4906 = float(k & 1);\n        float _4910 = float((k >> 1) & 1);\n        float _4914 = float((k >> 2) & 1);\n        if (_4906 > 0.5)\n        {\n            _4920 = _4813.x;\n        }\n        else\n        {\n            _4920 = 1.0 - _4813.x;\n        }\n        if (_4910 > 0.5)\n        {\n            _4933 = _4813.y;\n        }\n        else\n        {\n            _4933 = 1.0 - _4813.y;\n        }\n        if (_4914 > 0.5)\n        {\n            _4947 = _4813.z;\n        }\n        else\n        {\n            _4947 = 1.0 - _4813.z;\n        }\n        float _4957 = (_4920 * _4933) * _4947;\n        if (!(_4957 > 0.0))\n        {\n            continue;\n        }\n        vec3 _4970 = min(_4809 + vec3(_4906, _4910, _4914), _4800);\n        int _4990 = int(((_4733.x + _4970.x) + (_4728.x * (_4970.y + (_4728.y * _4970.z)))) + 0.5);\n        vec2 _5005 = vec2(float(_4990 % _4830) * 10.0, 1024.0 + (float(_4990 / _4830) * 11.0));\n        vec2 param_4 = _5005 + vec2(9.5, 10.5);\n        vec4 _5013 = fa_gi_fetch(param_4);\n        bool _5016 = _5013.y < 0.5;\n        bool _5025;\n        if (!_5016)\n        {\n            _5025 = _5013.x > _4738.y;\n        }\n        else\n        {\n            _5025 = _5016;\n        }\n        if (_5025)\n        {\n            continue;\n        }\n        vec3 _5037 = _4825 - (_4763 + (_4970 * _4756));\n        float _5040 = length(_5037);\n        vec3 _5046 = _5037 / vec3(max(_5040, 9.9999997473787516355514526367188e-05));\n        float _5056 = max(9.9999997473787516355514526367188e-05, (dot(-_5046, n) + 1.0) * 0.5);\n        float w = _4957 * (_5056 * _5056);\n        vec3 param_5 = _5046;\n        vec2 param_6 = (_5005 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _5076 = fa_gi_fetch(param_6);\n        float _5083 = _5040 / max(_4733.z, 9.9999997473787516355514526367188e-05);\n        float _5086 = _5076.x;\n        if (_5083 > _5086)\n        {\n            float _5099 = max(_5076.y - (_5086 * _5086), 0.0);\n            float _5104 = _5083 - _5086;\n            float _5113 = _5099 / max(_5099 + (_5104 * _5104), 9.9999999600419720025001879548654e-13);\n            w *= ((_5113 * _5113) * _5113);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _5005 + vec2(0.5, 10.5);\n        vec2 param_8 = _5005 + vec2(1.5, 10.5);\n        vec2 param_9 = _5005 + vec2(2.5, 10.5);\n        vec2 param_10 = _5005 + vec2(3.5, 10.5);\n        vec2 param_11 = _5005 + vec2(4.5, 10.5);\n        vec2 param_12 = _5005 + vec2(5.5, 10.5);\n        vec2 param_13 = _5005 + vec2(6.5, 10.5);\n        vec2 param_14 = _5005 + vec2(7.5, 10.5);\n        vec2 param_15 = _5005 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _4835)) + (fa_gi_fetch(param_9).xyz * _4839)) + (fa_gi_fetch(param_10).xyz * _4843)) + (fa_gi_fetch(param_11).xyz * _4850)) + (fa_gi_fetch(param_12).xyz * _4857)) + (fa_gi_fetch(param_13).xyz * _4866)) + (fa_gi_fetch(param_14).xyz * _4873)) + (fa_gi_fetch(param_15).xyz * _4886)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_4785 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _5241;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _5241 = _4738.x;\n    }\n    else\n    {\n        _5241 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_4733.w * _5241);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _5265 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _5270 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _5275 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _5275) && (k < 8); k++)\n    {\n        int param = _5270 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _5265;\n        vec3 _5300 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5305 = param_3 * left;\n        acc += (_5300 * _5305);\n        left -= _5305;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _5334 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5334;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _5376 = vec4(fa_world_pos, 1.0);\n        vec2 _5395 = vec2(dot(fa_mesh_fs_params[26], _5376), dot(fa_mesh_fs_params[27], _5376)) / vec2(max(dot(fa_mesh_fs_params[28], _5376), 9.9999997473787516355514526367188e-05));\n        float _5404;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5404 = (_5395.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5404 = 0.5 - (_5395.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_5395.x * 0.5) + 0.5, _5404) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4175;\n    if (fa_lm.z > 0.5)\n    {\n        _4175 = 0.0;\n    }\n    else\n    {\n        _4175 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4186 = _4175 < 1.0;\n    bool _4192;\n    if (_4186)\n    {\n        int param = li;\n        _4192 = fa_light_baked(param);\n    }\n    else\n    {\n        _4192 = _4186;\n    }\n    return _4192 ? _4175 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _599 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _612 = (c - (ru * hx)) - p;\n        vec3 _618 = ru * (2.0 * hx);\n        float _624 = max(dot(_618, _618), 9.9999999392252902907785028219223e-09);\n        float _628 = dot(_612, _618);\n        float t = clamp((-_628) / _624, 0.0, 1.0);\n        if (_599)\n        {\n            float _643 = dot(r, _618);\n            float _649 = _624 - (_643 * _643);\n            if (abs(_649) > (9.9999997473787516355514526367188e-06 * _624))\n            {\n                t = clamp(((dot(r, _612) * _643) - _628) / _649, 0.0, 1.0);\n            }\n        }\n        return (p + _612) + (_618 * t);\n    }\n    vec3 q = p;\n    float _681 = dot(r, axis);\n    bool _689;\n    if (_599)\n    {\n        _689 = abs(_681) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _689 = _599;\n    }\n    if (_689)\n    {\n        float _699 = dot(c - p, axis) / _681;\n        if (_699 > 0.0)\n        {\n            q = p + (r * _699);\n        }\n    }\n    vec3 _712 = q - c;\n    vec2 xy = vec2(dot(_712, ru), dot(_712, uu));\n    if (shape > 0.5)\n    {\n        float _727 = length(xy);\n        if (_727 > hx)\n        {\n            xy *= (hx / _727);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _519 = dot(d, right);\n    float _523 = dot(d, up);\n    float _534;\n    if (((_519 * _519) + (_523 * _523)) > 1.0000000133514319600180897396058e-10)\n    {\n        _534 = atan(_523, _519) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _534 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_534 - floor(_534)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _369 = abs(d);\n    float _371 = _369.x;\n    float _373 = _369.y;\n    bool _374 = _371 >= _373;\n    bool _382;\n    if (_374)\n    {\n        _382 = _371 >= _369.z;\n    }\n    else\n    {\n        _382 = _374;\n    }\n    int _383;\n    if (_382)\n    {\n        _383 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _398;\n        if (_373 >= _369.z)\n        {\n            _398 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _398 = (d.z > 0.0) ? 4 : 5;\n        }\n        _383 = _398;\n    }\n    return _383;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _765 = fa_light_base(param);\n    bool _769 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _765;\n    vec4 _773 = fa_light_texel(param_1);\n    int param_2 = _765 + 1;\n    vec4 _778 = fa_light_texel(param_2);\n    float _781 = _778.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _793 = _769 && (_781 > 2.5);\n    fa_light_is_area = _793;\n    bool _795 = _781 < 0.5;\n    vec3 l;\n    if (_795)\n    {\n        l = normalize(_773.xyz);\n        if (_769)\n        {\n            int param_3 = _765 + 6;\n            vec4 _809 = fa_light_texel(param_3);\n            if (_809.z > 0.5)\n            {\n                int param_4 = _765 + 4;\n                vec4 _819 = fa_light_texel(param_4);\n                int param_5 = _765 + 5;\n                vec4 _824 = fa_light_texel(param_5);\n                vec2 param_6 = _809.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _819.xyz) * _819.w, (-dot(world_pos, _824.xyz)) * _824.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _854 = _773.xyz;\n        vec3 _856 = _854 - world_pos;\n        vec3 to_light = _856;\n        float _859 = length(_856);\n        float reach = _859;\n        bool front = true;\n        if (_793)\n        {\n            int param_8 = _765 + 7;\n            reach = max(_859 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _765 + 4;\n            vec4 _883 = fa_light_texel(param_9);\n            int param_10 = _765 + 5;\n            vec4 _888 = fa_light_texel(param_10);\n            int param_11 = _765 + 6;\n            vec4 _893 = fa_light_texel(param_11);\n            float _894 = _893.w;\n            int param_12 = _765 + 2;\n            vec3 _901 = normalize(fa_light_texel(param_12).xyz);\n            bool _903 = _894 > 1.5;\n            bool _911;\n            if (!_903)\n            {\n                _911 = dot(_901, to_light) < 0.0;\n            }\n            else\n            {\n                _911 = _903;\n            }\n            front = _911;\n            vec3 r = vec3(0.0);\n            vec3 _920 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _924 = dot(n, n) > 0.5;\n            bool _932;\n            if (_924)\n            {\n                _932 = dot(_920, _920) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _932 = _924;\n            }\n            if (_932)\n            {\n                r = reflect(-normalize(_920), normalize(n));\n            }\n            vec3 param_13 = _854;\n            vec3 param_14 = _901;\n            vec3 param_15 = _883.xyz;\n            vec3 param_16 = _888.xyz;\n            float param_17 = _883.w;\n            float param_18 = _888.w;\n            float param_19 = _894;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _968 = length(to_light);\n        dist = _968;\n        l = to_light / vec3(max(_968, 9.9999997473787516355514526367188e-05));\n        float _982 = reach / max(_773.w, 0.001000000047497451305389404296875);\n        float _988 = clamp(1.0 - (_982 * _982), 0.0, 1.0);\n        float _990;\n        if (front)\n        {\n            _990 = _988 * _988;\n        }\n        else\n        {\n            _990 = 0.0;\n        }\n        atten = _990;\n        bool _1001 = _781 < 2.5;\n        if ((_781 > 1.5) && _1001)\n        {\n            int param_22 = _765 + 2;\n            vec4 _1009 = fa_light_texel(param_22);\n            float _1019 = _1009.w;\n            int param_23 = _765 + 3;\n            vec4 _1024 = fa_light_texel(param_23);\n            float _1025 = _1024.x;\n            float cos_inner = _1025;\n            if (_1025 > 1.5)\n            {\n                cos_inner = mix(_1019, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1019, cos_inner, dot(-l, normalize(_1009.xyz)));\n        }\n        if (_769 && (_781 < 1.5))\n        {\n            int param_24 = _765 + 6;\n            vec4 _1049 = fa_light_texel(param_24);\n            if (_1049.z > 0.5)\n            {\n                vec3 _1057 = -to_light;\n                int param_25 = _765 + 4;\n                int param_26 = _765 + 5;\n                vec3 _1071 = fa_light_texel(param_25).xyz;\n                vec3 _1075 = fa_light_texel(param_26).xyz;\n                vec3 _1084 = vec3(dot(_1057, _1071), dot(_1057, _1075), dot(_1057, cross(_1071, _1075)));\n                vec3 param_27 = _1084;\n                int _1088 = fa_cube_face(param_27);\n                int param_28 = _1088;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1115 = vec2(dot(_1084, cross(param_29, param_30)), dot(_1084, param_30)) / vec2(max(dot(_1084, param_29), 9.9999997473787516355514526367188e-05));\n                int _1119 = _1088 / 3;\n                vec2 param_31 = _1049.xy + (vec2(float(_1088 - (_1119 * 3)), float(_1119)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1115.x), 0.5 - (0.5 * _1115.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _765 + 7;\n            vec4 _1149 = fa_light_texel(param_33);\n            if (_1149.z > 0.5)\n            {\n                int param_34 = _765 + 2;\n                int param_35 = _765 + 4;\n                int param_36 = _765 + 5;\n                vec2 param_37 = _1149.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_769 && _1001)\n            {\n                int param_42 = _765 + 6;\n                vec4 _1196 = fa_light_texel(param_42);\n                int param_43 = _765 + 7;\n                vec4 _1201 = fa_light_texel(param_43);\n                bool _1204 = _1196.z > 0.5;\n                bool _1211;\n                if (!_1204)\n                {\n                    _1211 = _1201.z > 0.5;\n                }\n                else\n                {\n                    _1211 = _1204;\n                }\n                if (_1211)\n                {\n                    int param_44 = _765 + 2;\n                    vec4 _1218 = fa_light_texel(param_44);\n                    vec3 _1222 = normalize(_1218.xyz);\n                    int param_45 = _765 + 4;\n                    vec4 _1227 = fa_light_texel(param_45);\n                    int param_46 = _765 + 5;\n                    vec4 _1232 = fa_light_texel(param_46);\n                    if (_1204)\n                    {\n                        vec3 _1240 = -to_light;\n                        float _1247 = _1218.w;\n                        float _1263 = 0.5 / max(dot(_1240, _1222) * (sqrt(max(1.0 - (_1247 * _1247), 0.0)) / max(_1247, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1196.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1240, _1227.xyz) * _1263), 0.5 - (dot(_1240, _1232.xyz) * _1263));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1201.z > 0.5)\n                    {\n                        vec2 param_49 = _1201.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1222;\n                        vec3 param_52 = _1227.xyz;\n                        vec3 param_53 = _1232.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6096 = _778.xyz * atten;\n    if (_769)\n    {\n        _6096 *= fa_light_tint;\n    }\n    int _1331;\n    if (_795)\n    {\n        _1331 = 0;\n    }\n    else\n    {\n        _1331 = ((_781 > 1.5) && (_781 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6096, atten, 1.0, dist, _1331);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2120 = fa_shadow_depth(param, param_1);\n    float _2124;\n    if (conv.x < 0.5)\n    {\n        _2124 = _2120;\n    }\n    else\n    {\n        _2124 = (conv.y * conv.z) / (conv.z - (_2120 * (conv.z - conv.y)));\n    }\n    return _2124;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2170 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2176 = vec2(cos(_2170), sin(_2170));\n    vec2 dir = _2176;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2185;\n        if (k < 0.0)\n        {\n            _2185 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2185 = k;\n        }\n        float _2204 = clamp((_2185 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2223 = sqrt((float(i) + 0.5) * 0.0625) * _2204;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2223));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2237 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2237 < (zr - (_2223 * plane)))\n            {\n                sum += _2237;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2265 = sum / cnt;\n        float _2275;\n        if (k < 0.0)\n        {\n            _2275 = (-k) / max(_2265, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2275 = k;\n        }\n        radius = clamp(((max(zr - _2265, 0.0) * unit) * _2275) / texel_m, 1.5, 16.0);\n        dir = _2176;\n    }\n    float lit = 0.0;\n    int _2301 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2301; i_1++)\n    {\n        float _2320 = sqrt((float(i_1) + 0.5) / float(_2301)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2320));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2320 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2301);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2525 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2532;\n    if (!_2525)\n    {\n        _2532 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2532 = _2525;\n    }\n    if (_2532)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2545 = fa_light_texel(param);\n    float _2546 = _2545.x;\n    if (_2546 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2555 = int(_2546 + 0.5);\n    int param_1 = _2555;\n    vec4 _2559 = fa_light_texel(param_1);\n    int param_2 = _2555 + 1;\n    vec4 _2564 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2567 = _2559.y;\n    if (_2567 > 0.0)\n    {\n        float _2584 = 1.0 - smoothstep(0.75 * _2567, _2567, length(world - fa_shadows[27].xyz));\n        fade = _2584;\n        if (_2584 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2559.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2608 = (_2555 + 2) + (face * 6);\n    int param_4 = _2608;\n    int param_5 = _2608 + 1;\n    int param_6 = _2608 + 3;\n    vec4 _2622 = fa_light_texel(param_6);\n    int param_7 = _2608 + 4;\n    vec4 _2627 = fa_light_texel(param_7);\n    int param_8 = _2608 + 5;\n    vec4 _2632 = fa_light_texel(param_8);\n    float _2644 = _2632.x * max(dot(_2622, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2649 = clamp(dot(n, l), 0.0, 1.0);\n    float _2672 = clamp(dot(n, _2622.xyz), -1.0, 1.0);\n    float _2691 = min(sqrt(1.0 - (_2672 * _2672)) / max(abs(dot(n, world - lpos)) / max(dot(_2622, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2694 = _2564.y;\n    float _2696;\n    if (_2694 > 0.0)\n    {\n        _2696 = _2694;\n    }\n    else\n    {\n        _2696 = 1.5 * _2644;\n    }\n    vec4 _2716 = vec4(world + (n * (_2696 * sqrt(1.0 - (_2649 * _2649)))), 1.0);\n    float _2720 = dot(_2622, _2716);\n    float _2723 = _2632.y;\n    if (_2720 < _2723)\n    {\n        return 1.0;\n    }\n    vec2 _2738 = vec2(dot(fa_light_texel(param_4), _2716), dot(fa_light_texel(param_5), _2716)) / vec2(_2720);\n    float _2740 = _2738.x;\n    bool _2743 = _2740 < _2627.x;\n    bool _2752;\n    if (!_2743)\n    {\n        _2752 = _2740 > _2627.z;\n    }\n    else\n    {\n        _2752 = _2743;\n    }\n    bool _2761;\n    if (!_2752)\n    {\n        _2761 = _2738.y < _2627.y;\n    }\n    else\n    {\n        _2761 = _2752;\n    }\n    bool _2770;\n    if (!_2761)\n    {\n        _2770 = _2738.y > _2627.w;\n    }\n    else\n    {\n        _2770 = _2761;\n    }\n    if (_2770)\n    {\n        return 1.0;\n    }\n    float _2776 = _2564.x;\n    float _2778;\n    if (_2776 > 0.0)\n    {\n        _2778 = _2776;\n    }\n    else\n    {\n        _2778 = 1.5 * _2644;\n    }\n    vec2 param_9 = _2738;\n    vec4 param_10 = _2627;\n    float param_11 = _2720 - (_2778 * (1.0 + (0.5 * _2691)));\n    float param_12 = _2644;\n    float param_13 = 1.0;\n    float param_14 = _2632.z * 0.25;\n    float param_15 = (_2644 * min(_2691, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2723, _2632.z);\n    int param_17 = int(_2559.z + 0.5);\n    float param_18 = _2559.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3290 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3296;\n    if (_3290)\n    {\n        _3296 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3296 = _3290;\n    }\n    bool _3302;\n    if (_3296)\n    {\n        _3302 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3302 = _3296;\n    }\n    if (_3302)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3314 = fa_light_texel(param);\n        float _3315 = _3314.z;\n        if (_3315 > 0.5)\n        {\n            float _3328 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3331 = fwidth(_3328);\n            float _3335 = min(1.5 * _3331, 0.100000001490116119384765625 * _3328);\n            vec4 _3341 = vec4(world, 1.0);\n            float _3346 = dot(fa_mesh_fs_params[28], _3341);\n            if (_3346 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3363 = vec2(dot(fa_mesh_fs_params[26], _3341), dot(fa_mesh_fs_params[27], _3341)) / vec2(_3346);\n                float _3368 = (_3363.x * 0.5) + 0.5;\n                float _3372;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3372 = (_3363.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3372 = 0.5 - (_3363.y * 0.5);\n                }\n                bool _3388 = _3368 >= 0.0;\n                bool _3394;\n                if (_3388)\n                {\n                    _3394 = _3368 < 1.0;\n                }\n                else\n                {\n                    _3394 = _3388;\n                }\n                bool _3400;\n                if (_3394)\n                {\n                    _3400 = _3372 >= 0.0;\n                }\n                else\n                {\n                    _3400 = _3394;\n                }\n                bool _3406;\n                if (_3400)\n                {\n                    _3406 = _3372 < 1.0;\n                }\n                else\n                {\n                    _3406 = _3400;\n                }\n                if (_3406)\n                {\n                    ivec2 _3423 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3424 = clamp(ivec2(vec2(_3368, _3372) * fa_mesh_fs_params[24].zw), ivec2(0), _3423);\n                    ivec2 _3436;\n                    ivec2 _3442;\n                    ivec2 _3449;\n                    float _3500;\n                    float _3521;\n                    for (int k = 0; k < 5; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3436 = ivec2(0);\n                        }\n                        else\n                        {\n                            if (k == 1)\n                            {\n                                _3442 = ivec2(1, 0);\n                            }\n                            else\n                            {\n                                if (k == 2)\n                                {\n                                    _3449 = ivec2(-1, 0);\n                                }\n                                else\n                                {\n                                    bvec2 _3460 = bvec2(k == 3);\n                                    _3449 = ivec2(_3460.x ? ivec2(0, 1).x : ivec2(0, -1).x, _3460.y ? ivec2(0, 1).y : ivec2(0, -1).y);\n                                }\n                                _3442 = _3449;\n                            }\n                            _3436 = _3442;\n                        }\n                        vec4 _3477 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3424 + _3436, ivec2(0), _3423), 0);\n                        bool _3480 = _3477.w > 0.5;\n                        bool _3494;\n                        if (_3480)\n                        {\n                            _3494 = abs(_3328 - _3477.x) <= (((0.00200000009499490261077880859375 * _3328) + 0.00999999977648258209228515625) + _3335);\n                        }\n                        else\n                        {\n                            _3494 = _3480;\n                        }\n                        if (_3494)\n                        {\n                            if (_3315 < 1.5)\n                            {\n                                _3500 = 1.0;\n                            }\n                            else\n                            {\n                                _3500 = (_3315 < 2.5) ? 256.0 : 65536.0;\n                            }\n                            float _3517 = mod(floor(_3477.z / _3500), 256.0) * 0.0039215688593685626983642578125;\n                            if (fa_mesh_fs_params[25].z > 0.5)\n                            {\n                                int param_1 = li;\n                                vec3 param_2 = lpos;\n                                vec3 param_3 = world;\n                                vec3 param_4 = n;\n                                vec3 param_5 = l;\n                                _3521 = min(_3517, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                            }\n                            else\n                            {\n                                _3521 = _3517;\n                            }\n                            return _3521;\n                        }\n                    }\n                }\n            }\n            float _3546;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3546 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3546 = 1.0;\n            }\n            return _3546;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2063;\n    if (i == 0)\n    {\n        _2063 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2079;\n        if (i == 1)\n        {\n            _2079 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2087;\n            if (i == 2)\n            {\n                _2087 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2087 = fa_shadows[24].w;\n            }\n            _2079 = _2087;\n        }\n        _2063 = _2079;\n    }\n    return _2063;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2366 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2371 = clamp(dot(n, l), 0.0, 1.0);\n    float _2377 = sqrt(1.0 - (_2371 * _2371));\n    float _2385 = min(_2377 / max(_2371, 0.20000000298023223876953125), 4.0);\n    float _2390;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2390 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2390 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2415 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2390 * _2377)), 1.0);\n    float _2422 = _2415.x;\n    bool _2425 = _2422 < fa_shadows[ci * 1 + 16].x;\n    bool _2434;\n    if (!_2425)\n    {\n        _2434 = _2422 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2434 = _2425;\n    }\n    bool _2443;\n    if (!_2434)\n    {\n        _2443 = _2415.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2443 = _2434;\n    }\n    bool _2452;\n    if (!_2443)\n    {\n        _2452 = _2415.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2452 = _2443;\n    }\n    bool _2459;\n    if (!_2452)\n    {\n        _2459 = _2415.z > 1.0;\n    }\n    else\n    {\n        _2459 = _2452;\n    }\n    if (_2459)\n    {\n        return -1.0;\n    }\n    float _2467;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2467 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2467 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2415.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2415.z - ((_2467 * (1.0 + (0.5 * _2385))) / _2366);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2366;\n    float param_5 = _2366 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2385, 3.0)) * 0.5) / _2366;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2845 = int(fa_shadows[25].x + 0.5);\n    if (_2845 < 1)\n    {\n        return 1.0;\n    }\n    float _2860 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2845 - 1;\n    if (_2860 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2872 = _2845 > 1;\n    bool _2879;\n    if (_2872)\n    {\n        _2879 = _2860 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2879 = _2872;\n    }\n    if (_2879)\n    {\n        ci = 1;\n    }\n    bool _2883 = _2845 > 2;\n    bool _2890;\n    if (_2883)\n    {\n        _2890 = _2860 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2890 = _2883;\n    }\n    if (_2890)\n    {\n        ci = 2;\n    }\n    bool _2894 = _2845 > 3;\n    bool _2901;\n    if (_2894)\n    {\n        _2901 = _2860 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2901 = _2894;\n    }\n    if (_2901)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2912 = min(_2845, 4);\n    float _2953;\n    for (int c = ci; c < _2912; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2932 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2932;\n            break;\n        }\n        if (_2932 < 0.0)\n        {\n            continue;\n        }\n        s = _2932;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2953 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2953 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _2972 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2953, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2860 - (fa_shadow_split_at(param_7) - _2972)) / _2972, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3004;\n        if ((ci + 1) < _2845)\n        {\n            _3004 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3004 = 1.0;\n        }\n        s = mix(s, _3004, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3109 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3115;\n    if (_3109)\n    {\n        _3115 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3115 = _3109;\n    }\n    if (_3115)\n    {\n        float _3129 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        float _3132 = fwidth(_3129);\n        vec4 _3142 = vec4(fa_world_pos, 1.0);\n        float _3148 = dot(fa_mesh_fs_params[28], _3142);\n        if (_3148 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3167 = vec2(dot(fa_mesh_fs_params[26], _3142), dot(fa_mesh_fs_params[27], _3142)) / vec2(_3148);\n            float _3172 = (_3167.x * 0.5) + 0.5;\n            float _3176;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3176 = (_3167.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3176 = 0.5 - (_3167.y * 0.5);\n            }\n            bool _3192 = _3172 >= 0.0;\n            bool _3198;\n            if (_3192)\n            {\n                _3198 = _3172 < 1.0;\n            }\n            else\n            {\n                _3198 = _3192;\n            }\n            bool _3204;\n            if (_3198)\n            {\n                _3204 = _3176 >= 0.0;\n            }\n            else\n            {\n                _3204 = _3198;\n            }\n            bool _3210;\n            if (_3204)\n            {\n                _3210 = _3176 < 1.0;\n            }\n            else\n            {\n                _3210 = _3204;\n            }\n            if (_3210)\n            {\n                vec4 _3236 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3172, _3176) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3239 = _3236.w > 0.5;\n                bool _3255;\n                if (_3239)\n                {\n                    _3255 = abs(_3129 - _3236.x) <= (((0.00200000009499490261077880859375 * _3129) + 0.00999999977648258209228515625) + min(1.5 * _3132, 0.100000001490116119384765625 * _3129));\n                }\n                else\n                {\n                    _3255 = _3239;\n                }\n                if (_3255)\n                {\n                    float _3261;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3261 = min(_3236.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3261 = _3236.y;\n                    }\n                    return _3261;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3917 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3924;\n    if (!_3917)\n    {\n        _3924 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3924 = _3917;\n    }\n    if (_3924)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3937 = fa_light_texel(param);\n    float _3938 = _3937.y;\n    float len = _3938;\n    if (_3938 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3950 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3959 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3950);\n    if (_3959 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3965 = len;\n    float _3968 = min(_3965, 0.89999997615814208984375 * dist);\n    len = _3968;\n    float _3974 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3950);\n    float _3979 = _3974 + (0.5 * _3968);\n    vec3 _3985 = world + (gn * _3974);\n    float _3987 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4049;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4003 = (float(k) + _3987) * 0.083333335816860198974609375;\n        vec3 _4011 = _3985 + (l * (_4003 * len));\n        vec4 _4017 = vec4(_4011, 1.0);\n        float _4022 = dot(fa_mesh_fs_params[28], _4017);\n        if (_4022 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4040 = vec2(dot(fa_mesh_fs_params[26], _4017), dot(fa_mesh_fs_params[27], _4017)) / vec2(_4022);\n        float _4044 = _4040.x * 0.5;\n        float _4045 = _4044 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4049 = (_4040.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4049 = 0.5 - (_4040.y * 0.5);\n        }\n        bool _4065 = _4045 < 0.0;\n        bool _4072;\n        if (!_4065)\n        {\n            _4072 = _4045 >= 1.0;\n        }\n        else\n        {\n            _4072 = _4065;\n        }\n        bool _4079;\n        if (!_4072)\n        {\n            _4079 = _4049 < 0.0;\n        }\n        else\n        {\n            _4079 = _4072;\n        }\n        bool _4086;\n        if (!_4079)\n        {\n            _4086 = _4049 >= 1.0;\n        }\n        else\n        {\n            _4086 = _4079;\n        }\n        if (_4086)\n        {\n            break;\n        }\n        vec4 _4110 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4045, _4049) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4110.w < 0.5)\n        {\n            continue;\n        }\n        float _4128 = (dot(fa_mesh_fs_params[29].xyz, _4011) + fa_mesh_fs_params[29].w) - _4110.x;\n        if ((_4128 > _3974) && (_4128 < _3979))\n        {\n            occ = max(occ, (1.0 - (_4003 * _4003)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4045, 0.5 - _4044), min(_4049, 1.0 - _4049))));\n        }\n    }\n    return 1.0 - (occ * _3959);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4231 = fa_baked_keep(param);\n    if (_4231 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4257 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6122 = _4257.color;\n    float _6123 = _4257.attenuation;\n    float _6124 = _4257.shadow;\n    bool _4260 = _4257.type == 0;\n    if (_4260 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4257.direction;\n        float _4271 = fa_shadow_factor(param_5, param_6);\n        _6124 = _4271;\n        _6122 *= _4271;\n    }\n    else\n    {\n        bool _4282 = _4257.type != 0;\n        bool _4288;\n        if (_4282)\n        {\n            _4288 = _6123 > 0.0;\n        }\n        else\n        {\n            _4288 = _4282;\n        }\n        if (_4288)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4257.direction;\n            float _4307 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6124 = _4307;\n            _6122 *= _4307;\n        }\n    }\n    bool _4317 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4323;\n    if (_4317)\n    {\n        _4323 = _6123 > 0.0;\n    }\n    else\n    {\n        _4323 = _4317;\n    }\n    if (_4323)\n    {\n        float _4330;\n        if (_4260)\n        {\n            _4330 = 1000000000.0;\n        }\n        else\n        {\n            _4330 = _4257._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4257.direction;\n        float param_18 = _4330;\n        float _4348 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6124 *= _4348;\n        _6122 *= _4348;\n    }\n    float _4361 = _6123;\n    float _4362 = _4361 * _4231;\n    _6123 = _4362;\n    vec3 _4366 = _6122;\n    vec3 _4367 = _4366 * _4231;\n    _6122 = _4367;\n    return LightSample(_4257.direction, _4367, _4362, _6124, _4257._distance, _4257.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3032 = int(fa_shadows[25].x + 0.5);\n    float _3042 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3047 = _3032 > 0;\n    bool _3056;\n    if (_3047)\n    {\n        int param = _3032 - 1;\n        _3056 = _3042 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3056 = _3047;\n    }\n    if (_3056)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3062 = _3032 > 1;\n        bool _3069;\n        if (_3062)\n        {\n            _3069 = _3042 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3069 = _3062;\n        }\n        if (_3069)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3075 = _3032 > 2;\n        bool _3082;\n        if (_3075)\n        {\n            _3082 = _3042 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3082 = _3075;\n        }\n        if (_3082)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3088 = _3032 > 3;\n        bool _3095;\n        if (_3088)\n        {\n            _3095 = _3042 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3095 = _3088;\n        }\n        if (_3095)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5943 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5943 = -_5943;\n    }\n    vec3 _5517 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5943, fa_world_tangent, fa_uv, fa_vertex_color, _5517, gl_FrontFacing);\n    Surface _5525 = fa_standard_surface(param_1);\n    vec3 _5974 = _5525.albedo;\n    float _5975 = _5525.alpha;\n    vec3 _5976 = _5525.normal;\n    float _5977 = _5525.metallic;\n    float _5978 = _5525.roughness;\n    float _5979 = _5525.occlusion;\n    vec3 _5980 = _5525.emission;\n    float _5981 = _5525.clearcoat;\n    float _5982 = _5525.clearcoat_roughness;\n    vec3 _5983 = _5525.sheen_color;\n    float _5984 = _5525.sheen_roughness;\n    float _5985 = _5525.anisotropy;\n    float _5986 = _5525.anisotropy_rotation;\n    float _5987 = _5525.specular;\n    float _5988 = _5525.ior;\n    vec3 _5989 = _5525.specular_color;\n    float _5990 = _5525.transmission;\n    float _5991 = _5525.thickness;\n    vec3 _5992 = _5525.attenuation_color;\n    float _5993 = _5525.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5943, fa_world_tangent, fa_uv, fa_vertex_color, _5517, gl_FrontFacing);\n    Surface param_3 = _5525;\n    surface(param_2, param_3);\n    _5974 = param_3.albedo;\n    _5975 = param_3.alpha;\n    _5976 = param_3.normal;\n    _5977 = param_3.metallic;\n    _5978 = param_3.roughness;\n    _5979 = param_3.occlusion;\n    _5980 = param_3.emission;\n    _5981 = param_3.clearcoat;\n    _5982 = param_3.clearcoat_roughness;\n    _5983 = param_3.sheen_color;\n    _5984 = param_3.sheen_roughness;\n    _5985 = param_3.anisotropy;\n    _5986 = param_3.anisotropy_rotation;\n    _5987 = param_3.specular;\n    _5988 = param_3.ior;\n    _5989 = param_3.specular_color;\n    _5990 = param_3.transmission;\n    _5991 = param_3.thickness;\n    _5992 = param_3.attenuation_color;\n    _5993 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5943;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5974 = param_6;\n    _5976 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5974;\n    }\n    else\n    {\n        vec3 _5564 = _5976;\n        vec3 _5565 = normalize(_5564);\n        _5976 = _5565;\n        vec3 param_8 = _5565;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _5974) * _5979;\n        int _5584 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5584; ln++)\n        {\n            int param_9 = ln;\n            int _5597 = fa_cl_light(param_9);\n            int param_10 = _5597;\n            if (fa_baked_keep(param_10) <= 0.0)\n            {\n                continue;\n            }\n            int param_11 = _5597;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _5943;\n            LightSample _5613 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _5943, fa_world_tangent, fa_uv, fa_vertex_color, _5517, gl_FrontFacing);\n            Surface param_15 = Surface(_5974, _5975, _5976, _5977, _5978, _5979, _5980, _5981, _5982, _5983, _5984, _5985, _5986, _5987, _5988, _5989, _5990, _5991, _5992, _5993);\n            LightSample param_16 = _5613;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _5628 = result;\n    vec3 _5629 = _5628 + _5980;\n    result = _5629;\n    vec3 param_17 = _5629;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _5638 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5645;\n    if (!_5638)\n    {\n        _5645 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5645 = _5638;\n    }\n    if (_5645)\n    {\n        vec3 _5654 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5660 = dot(_5654, fa_mesh_fs_params[9].xyz);\n        bool _5664 = fa_mesh_fs_params[9].w > 0.5;\n        float _5665;\n        if (_5664)\n        {\n            _5665 = _5660;\n        }\n        else\n        {\n            _5665 = length(_5654);\n        }\n        float _5677 = _5665 - fa_mesh_fs_params[8].x;\n        if (_5677 > 0.0)\n        {\n            float _5686 = fa_mesh_fs_params[7].w * _5677;\n            float tau = _5686 * _5686;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5702;\n                if (_5664)\n                {\n                    _5702 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5660);\n                }\n                else\n                {\n                    _5702 = fa_mesh_fs_params[0].y;\n                }\n                float _5723 = mix(_5702, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5665, 0.0, 1.0));\n                float _5727 = fa_world_pos.y - _5723;\n                float _5732 = _5723 - fa_mesh_fs_params[8].z;\n                float _5737 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5740 = _5732 <= 0.0;\n                bool _5741 = !_5740;\n                bool _5747;\n                if (_5741)\n                {\n                    _5747 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5747 = _5740;\n                }\n                float _5748;\n                if (_5747)\n                {\n                    _5748 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5748 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5732, 80.0));\n                }\n                bool _5775;\n                if (_5741)\n                {\n                    _5775 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5775 = _5740;\n                }\n                float _5776;\n                if (_5775)\n                {\n                    _5776 = fa_mesh_fs_params[8].y * _5732;\n                }\n                else\n                {\n                    _5776 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5732, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5801 = _5737 <= 0.0;\n                bool _5808;\n                if (!_5801)\n                {\n                    _5808 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5808 = _5801;\n                }\n                float _5809;\n                if (_5808)\n                {\n                    _5809 = fa_mesh_fs_params[8].y * _5737;\n                }\n                else\n                {\n                    _5809 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5737, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5836;\n                if (abs(_5727) < 0.001000000047497451305389404296875)\n                {\n                    _5836 = _5748;\n                }\n                else\n                {\n                    _5836 = (_5809 - _5776) / _5727;\n                }\n                tau += (_5677 * max(_5836, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5975);\n}\n\n",
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
            "inst_name": "_421",
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
