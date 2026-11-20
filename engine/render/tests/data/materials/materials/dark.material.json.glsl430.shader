{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "27973f29289cdb06f6da050426786ada05329a25848bb279986221a7a56fee4b",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[30];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1314 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1321;\n    if (!_1314)\n    {\n        _1321 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1321 = _1314;\n    }\n    bool _1329;\n    if (!_1321)\n    {\n        _1329 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1329 = _1321;\n    }\n    bool _1336;\n    if (!_1329)\n    {\n        _1336 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1336 = _1329;\n    }\n    bool _1343;\n    if (!_1336)\n    {\n        _1343 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1343 = _1336;\n    }\n    if (_1343)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1353 = vec4(world_pos, 1.0);\n    float _1359 = dot(fa_mesh_fs_params[16], _1353);\n    if (!(_1359 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1381 = vec2(dot(fa_mesh_fs_params[14], _1353), dot(fa_mesh_fs_params[15], _1353)) / vec2(_1359);\n    int _1385 = int(fa_mesh_fs_params[18].x);\n    int _1389 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1389) + clamp(int(floor(((_1381.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1389 - 1)) * _1385)) + clamp(int(floor(((_1381.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1385 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1465 = fa_cluster_texel(param);\n    return ivec2(int(_1465.x), int(_1465.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3496 = fa_cluster_lookup(param);\n    fa_cl_slot = _3496.x;\n    fa_cl_local = _3496.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3696 = fa_linear_to_srgb(param);\n        c = _3696;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3704 = fa_srgb_to_linear(param_1);\n            c = _3704;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _269;\n    if (i.front_facing)\n    {\n        _269 = i.world_normal;\n    }\n    else\n    {\n        _269 = -i.world_normal;\n    }\n    vec3 _293 = normalize(i.world_tangent.xyz - (_269 * dot(_269, i.world_tangent.xyz)));\n    vec3 _320 = normalize(((_293 * m.x) + ((cross(_269, _293) * i.world_tangent.w) * m.y)) + (_269 * m.z));\n    vec3 _323;\n    if (i.front_facing)\n    {\n        _323 = _320;\n    }\n    else\n    {\n        _323 = -_320;\n    }\n    return _323;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3735 = fa_tex_fix(param_2, param_3);\n    vec4 _4769 = base_t;\n    _4769.x = _3735.x;\n    _4769.y = _3735.y;\n    _4769.z = _3735.z;\n    base_t = _4769;\n    vec4 _3749 = (_4769 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4621 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3781 = fa_tex_fix(param_6, param_7);\n        vec3 _3784 = (_3781 * 2.0) - vec3(1.0);\n        vec2 _3789 = _3784.xy * fa_mesh_fs_params[6].x;\n        vec3 _4777 = _3784;\n        _4777.x = _3789.x;\n        _4777.y = _3789.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4777;\n        _4621 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3817 = fa_tex_fix(param_12, param_13);\n    vec4 _4780 = mrt;\n    _4780.x = _3817.x;\n    _4780.y = _3817.y;\n    _4780.z = _3817.z;\n    mrt = _4780;\n    vec4 _3845 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3845.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3856 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3886 = fa_tex_fix(param_20, param_21);\n    float _4626 = fa_mesh_fs_params[20].x;\n    float _4627 = fa_mesh_fs_params[20].y;\n    float _4630 = fa_mesh_fs_params[20].z;\n    float _4629 = fa_mesh_fs_params[21].w;\n    float _4632 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4626 *= _3856.y;\n            _4627 *= _3856.z;\n            _4629 *= _3845.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4630 *= mrt.x;\n            _4632 *= mrt.w;\n        }\n    }\n    return Surface(_3749.xyz, _3749.w, _4621, clamp(fa_mesh_fs_params[5].x * _3817.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3817.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3856.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3886), _4626, _4627, fa_mesh_fs_params[21].xyz, _4629, _4630, fa_mesh_fs_params[20].w, _4632, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1545 = rect.zw - rect.xy;\n    vec2 _1549 = _1545 * atlas;\n    vec2 _1553 = ddx * _1549;\n    vec2 _1557 = ddy * _1549;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1545), clamp(0.5 * log2(max(max(dot(_1553, _1553), dot(_1557, _1557)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1590 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1597;\n    if (!_1590)\n    {\n        _1597 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1597 = _1590;\n    }\n    if (_1597)\n    {\n        return;\n    }\n    vec3 _1603 = dFdx(world_pos);\n    vec3 _1606 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1610 = fa_cluster_texel(param);\n    int _1614 = int(_1610.w);\n    if (_1614 < 1)\n    {\n        return;\n    }\n    int _1624 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1624;\n    vec4 _1628 = fa_light_texel(param_1);\n    vec2 _1631 = _1628.yz;\n    int _1635 = int(_1628.w);\n    int param_2 = _1624 + 1;\n    vec4 _1640 = fa_light_texel(param_2);\n    float _1641 = _1640.x;\n    int _1647 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1651 = int(_1610.z);\n    vec3 _1916;\n    for (int k = 0; k < _1614; k++)\n    {\n        int _1664 = _1651 + k;\n        int param_3 = _1635 + (_1664 >> 2);\n        int _1681 = (_1624 + 2) + (int(fa_light_texel(param_3)[_1664 & 3]) * 7);\n        int param_4 = _1681 + 6;\n        vec4 _1686 = fa_light_texel(param_4);\n        if (((int(_1686.w + 0.5) >> _1647) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1681;\n        vec4 _1701 = fa_light_texel(param_5);\n        int param_6 = _1681 + 1;\n        vec4 _1706 = fa_light_texel(param_6);\n        int param_7 = _1681 + 2;\n        vec4 _1711 = fa_light_texel(param_7);\n        vec3 _1714 = _1701.xyz;\n        float _1719 = dot(_1714, world_pos) + _1701.w;\n        vec3 _1721 = _1706.xyz;\n        float _1726 = dot(_1721, world_pos) + _1706.w;\n        vec3 _1728 = _1711.xyz;\n        float _1733 = dot(_1728, world_pos) + _1711.w;\n        bool _1738 = abs(_1719) > 0.5;\n        bool _1746;\n        if (!_1738)\n        {\n            _1746 = abs(_1726) > 0.5;\n        }\n        else\n        {\n            _1746 = _1738;\n        }\n        bool _1754;\n        if (!_1746)\n        {\n            _1754 = abs(_1733) > 0.5;\n        }\n        else\n        {\n            _1754 = _1746;\n        }\n        if (_1754)\n        {\n            continue;\n        }\n        float _1769 = clamp(dot(geo_normal, normalize(_1728)) * _1686.z, 0.0, 1.0);\n        if (_1769 <= 0.0)\n        {\n            continue;\n        }\n        float _1789 = (clamp((0.5 - abs(_1733)) * 10.0, 0.0, 1.0) * _1769) * _1686.x;\n        vec2 _1797 = vec2(_1719 + 0.5, 0.5 - _1726);\n        vec2 _1807 = vec2(dot(_1714, _1603), dot(_1721, _1603));\n        vec2 _1817 = vec2(dot(_1714, _1606), dot(_1721, _1606));\n        int param_8 = _1681 + 5;\n        vec4 _1822 = fa_light_texel(param_8);\n        int param_9 = _1681 + 3;\n        vec4 _1827 = fa_light_texel(param_9);\n        int param_10 = _1681 + 4;\n        vec4 _1832 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1822.xyz;\n        bool _1842 = _1827.z > _1827.x;\n        if (_1842)\n        {\n            vec4 param_11 = _1827;\n            vec2 param_12 = _1797;\n            vec2 param_13 = _1631;\n            vec2 param_14 = _1807;\n            vec2 param_15 = _1817;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1641 > 0.5) && (_1641 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1868 = fa_dc_to_linear(param_16);\n                vec4 _4701 = tx;\n                _4701.x = _1868.x;\n                _4701.y = _1868.y;\n                _4701.z = _1868.z;\n                tx = _4701;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1789 * tex_a) * _1822.w, 0.0, 1.0)));\n        if (_1832.z > _1832.x)\n        {\n            vec4 param_17 = _1832;\n            vec2 param_18 = _1797;\n            vec2 param_19 = _1631;\n            vec2 param_20 = _1807;\n            vec2 param_21 = _1817;\n            vec4 _1912 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1641 > 1.5)\n            {\n                vec3 param_22 = _1912.xyz;\n                vec3 _1922 = fa_dc_to_srgb(param_22);\n                _1916 = _1922;\n            }\n            else\n            {\n                _1916 = _1912.xyz;\n            }\n            vec3 _1931 = (_1916 * 2.0) - vec3(1.0);\n            vec2 _1936 = _1931.xy * _1686.y;\n            vec3 _1958 = (normalize(_1714) * _1936.x) + (normalize(_1721) * _1936.y);\n            vec3 _1961 = normalize(normal);\n            normal = normalize(mix(_1961, normalize((_1961 * max(_1931.z, 0.0500000007450580596923828125)) + (_1958 - (_1961 * dot(_1961, _1958)))), vec3(clamp(_1789 * (_1842 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3156 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3156;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _564 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _577 = (c - (ru * hx)) - p;\n        vec3 _583 = ru * (2.0 * hx);\n        float _589 = max(dot(_583, _583), 9.9999999392252902907785028219223e-09);\n        float _593 = dot(_577, _583);\n        float t = clamp((-_593) / _589, 0.0, 1.0);\n        if (_564)\n        {\n            float _608 = dot(r, _583);\n            float _614 = _589 - (_608 * _608);\n            if (abs(_614) > (9.9999997473787516355514526367188e-06 * _589))\n            {\n                t = clamp(((dot(r, _577) * _608) - _593) / _614, 0.0, 1.0);\n            }\n        }\n        return (p + _577) + (_583 * t);\n    }\n    vec3 q = p;\n    float _646 = dot(r, axis);\n    bool _654;\n    if (_564)\n    {\n        _654 = abs(_646) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _654 = _564;\n    }\n    if (_654)\n    {\n        float _664 = dot(c - p, axis) / _646;\n        if (_664 > 0.0)\n        {\n            q = p + (r * _664);\n        }\n    }\n    vec3 _677 = q - c;\n    vec2 xy = vec2(dot(_677, ru), dot(_677, uu));\n    if (shape > 0.5)\n    {\n        float _692 = length(xy);\n        if (_692 > hx)\n        {\n            xy *= (hx / _692);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _335 = abs(d);\n    float _337 = _335.x;\n    float _339 = _335.y;\n    bool _340 = _337 >= _339;\n    bool _348;\n    if (_340)\n    {\n        _348 = _337 >= _335.z;\n    }\n    else\n    {\n        _348 = _340;\n    }\n    int _349;\n    if (_348)\n    {\n        _349 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _364;\n        if (_339 >= _335.z)\n        {\n            _364 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _364 = (d.z > 0.0) ? 4 : 5;\n        }\n        _349 = _364;\n    }\n    return _349;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _484 = dot(d, right);\n    float _488 = dot(d, up);\n    float _499;\n    if (((_484 * _484) + (_488 * _488)) > 1.0000000133514319600180897396058e-10)\n    {\n        _499 = atan(_488, _484) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _499 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_499 - floor(_499)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _730 = fa_light_base(param);\n    bool _734 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _730;\n    vec4 _738 = fa_light_texel(param_1);\n    int param_2 = _730 + 1;\n    vec4 _743 = fa_light_texel(param_2);\n    float _746 = _743.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _758 = _734 && (_746 > 2.5);\n    fa_light_is_area = _758;\n    bool _760 = _746 < 0.5;\n    vec3 l;\n    if (_760)\n    {\n        l = normalize(_738.xyz);\n        if (_734)\n        {\n            int param_3 = _730 + 6;\n            vec4 _774 = fa_light_texel(param_3);\n            if (_774.z > 0.5)\n            {\n                int param_4 = _730 + 4;\n                vec4 _784 = fa_light_texel(param_4);\n                int param_5 = _730 + 5;\n                vec4 _789 = fa_light_texel(param_5);\n                vec2 param_6 = _774.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _784.xyz) * _784.w, (-dot(world_pos, _789.xyz)) * _789.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _819 = _738.xyz;\n        vec3 _821 = _819 - world_pos;\n        vec3 to_light = _821;\n        float _824 = length(_821);\n        float reach = _824;\n        bool front = true;\n        if (_758)\n        {\n            int param_8 = _730 + 7;\n            reach = max(_824 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _730 + 4;\n            vec4 _848 = fa_light_texel(param_9);\n            int param_10 = _730 + 5;\n            vec4 _853 = fa_light_texel(param_10);\n            int param_11 = _730 + 6;\n            vec4 _858 = fa_light_texel(param_11);\n            float _859 = _858.w;\n            int param_12 = _730 + 2;\n            vec3 _866 = normalize(fa_light_texel(param_12).xyz);\n            bool _868 = _859 > 1.5;\n            bool _876;\n            if (!_868)\n            {\n                _876 = dot(_866, to_light) < 0.0;\n            }\n            else\n            {\n                _876 = _868;\n            }\n            front = _876;\n            vec3 r = vec3(0.0);\n            vec3 _885 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _889 = dot(n, n) > 0.5;\n            bool _897;\n            if (_889)\n            {\n                _897 = dot(_885, _885) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _897 = _889;\n            }\n            if (_897)\n            {\n                r = reflect(-normalize(_885), normalize(n));\n            }\n            vec3 param_13 = _819;\n            vec3 param_14 = _866;\n            vec3 param_15 = _848.xyz;\n            vec3 param_16 = _853.xyz;\n            float param_17 = _848.w;\n            float param_18 = _853.w;\n            float param_19 = _859;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _933 = length(to_light);\n        dist = _933;\n        l = to_light / vec3(max(_933, 9.9999997473787516355514526367188e-05));\n        float _947 = reach / max(_738.w, 0.001000000047497451305389404296875);\n        float _953 = clamp(1.0 - (_947 * _947), 0.0, 1.0);\n        float _955;\n        if (front)\n        {\n            _955 = _953 * _953;\n        }\n        else\n        {\n            _955 = 0.0;\n        }\n        atten = _955;\n        bool _966 = _746 < 2.5;\n        if ((_746 > 1.5) && _966)\n        {\n            int param_22 = _730 + 2;\n            vec4 _974 = fa_light_texel(param_22);\n            float _984 = _974.w;\n            int param_23 = _730 + 3;\n            vec4 _989 = fa_light_texel(param_23);\n            float _990 = _989.x;\n            float cos_inner = _990;\n            if (_990 > 1.5)\n            {\n                cos_inner = mix(_984, 1.0, 0.25);\n            }\n            atten *= smoothstep(_984, cos_inner, dot(-l, normalize(_974.xyz)));\n        }\n        if (_734 && (_746 < 1.5))\n        {\n            int param_24 = _730 + 6;\n            vec4 _1014 = fa_light_texel(param_24);\n            if (_1014.z > 0.5)\n            {\n                vec3 _1022 = -to_light;\n                int param_25 = _730 + 4;\n                int param_26 = _730 + 5;\n                vec3 _1036 = fa_light_texel(param_25).xyz;\n                vec3 _1040 = fa_light_texel(param_26).xyz;\n                vec3 _1049 = vec3(dot(_1022, _1036), dot(_1022, _1040), dot(_1022, cross(_1036, _1040)));\n                vec3 param_27 = _1049;\n                int _1053 = fa_cube_face(param_27);\n                int param_28 = _1053;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1080 = vec2(dot(_1049, cross(param_29, param_30)), dot(_1049, param_30)) / vec2(max(dot(_1049, param_29), 9.9999997473787516355514526367188e-05));\n                int _1084 = _1053 / 3;\n                vec2 param_31 = _1014.xy + (vec2(float(_1053 - (_1084 * 3)), float(_1084)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1080.x), 0.5 - (0.5 * _1080.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _730 + 7;\n            vec4 _1114 = fa_light_texel(param_33);\n            if (_1114.z > 0.5)\n            {\n                int param_34 = _730 + 2;\n                int param_35 = _730 + 4;\n                int param_36 = _730 + 5;\n                vec2 param_37 = _1114.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_734 && _966)\n            {\n                int param_42 = _730 + 6;\n                vec4 _1161 = fa_light_texel(param_42);\n                int param_43 = _730 + 7;\n                vec4 _1166 = fa_light_texel(param_43);\n                bool _1169 = _1161.z > 0.5;\n                bool _1176;\n                if (!_1169)\n                {\n                    _1176 = _1166.z > 0.5;\n                }\n                else\n                {\n                    _1176 = _1169;\n                }\n                if (_1176)\n                {\n                    int param_44 = _730 + 2;\n                    vec4 _1183 = fa_light_texel(param_44);\n                    vec3 _1187 = normalize(_1183.xyz);\n                    int param_45 = _730 + 4;\n                    vec4 _1192 = fa_light_texel(param_45);\n                    int param_46 = _730 + 5;\n                    vec4 _1197 = fa_light_texel(param_46);\n                    if (_1169)\n                    {\n                        vec3 _1205 = -to_light;\n                        float _1212 = _1183.w;\n                        float _1228 = 0.5 / max(dot(_1205, _1187) * (sqrt(max(1.0 - (_1212 * _1212), 0.0)) / max(_1212, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1161.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1205, _1192.xyz) * _1228), 0.5 - (dot(_1205, _1197.xyz) * _1228));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1166.z > 0.5)\n                    {\n                        vec2 param_49 = _1166.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1187;\n                        vec3 param_52 = _1192.xyz;\n                        vec3 param_53 = _1197.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _4575 = _743.xyz * atten;\n    if (_734)\n    {\n        _4575 *= fa_light_tint;\n    }\n    int _1296;\n    if (_760)\n    {\n        _1296 = 0;\n    }\n    else\n    {\n        _1296 = ((_746 > 1.5) && (_746 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4575, atten, 1.0, dist, _1296);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2033;\n    if (i == 0)\n    {\n        _2033 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2049;\n        if (i == 1)\n        {\n            _2049 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2057;\n            if (i == 2)\n            {\n                _2057 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2057 = fa_shadows[24].w;\n            }\n            _2049 = _2057;\n        }\n        _2033 = _2049;\n    }\n    return _2033;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2090 = fa_shadow_depth(param, param_1);\n    float _2094;\n    if (conv.x < 0.5)\n    {\n        _2094 = _2090;\n    }\n    else\n    {\n        _2094 = (conv.y * conv.z) / (conv.z - (_2090 * (conv.z - conv.y)));\n    }\n    return _2094;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2021 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2021), sin(_2021)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2140 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2149;\n        if (k < 0.0)\n        {\n            _2149 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2149 = k;\n        }\n        float _2169 = clamp((_2149 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2140;\n            vec2 _2188 = fa_shadow_vogel(param_3, param_4, param_5) * _2169;\n            vec2 param_6 = uv + (_2188 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2200 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2200 < (zr - (length(_2188) * plane)))\n            {\n                sum += _2200;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2226 = sum / cnt;\n        float _2236;\n        if (k < 0.0)\n        {\n            _2236 = (-k) / max(_2226, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2236 = k;\n        }\n        radius = clamp(((max(zr - _2226, 0.0) * unit) * _2236) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2258 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2258; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2258;\n        float param_11 = _2140;\n        vec2 _2277 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2277 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2277) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2258);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2319 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2324 = clamp(dot(n, l), 0.0, 1.0);\n    float _2330 = sqrt(1.0 - (_2324 * _2324));\n    float _2337 = min(_2330 / max(_2324, 0.20000000298023223876953125), 4.0);\n    float _2342;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2342 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2342 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2367 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2342 * _2330)), 1.0);\n    float _2374 = _2367.x;\n    bool _2377 = _2374 < fa_shadows[ci * 1 + 16].x;\n    bool _2386;\n    if (!_2377)\n    {\n        _2386 = _2374 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2386 = _2377;\n    }\n    bool _2395;\n    if (!_2386)\n    {\n        _2395 = _2367.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2395 = _2386;\n    }\n    bool _2404;\n    if (!_2395)\n    {\n        _2404 = _2367.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2404 = _2395;\n    }\n    bool _2411;\n    if (!_2404)\n    {\n        _2411 = _2367.z > 1.0;\n    }\n    else\n    {\n        _2411 = _2404;\n    }\n    if (_2411)\n    {\n        return -1.0;\n    }\n    float _2419;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2419 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2419 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2367.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2367.z - ((_2419 * (1.0 + (0.5 * _2337))) / _2319);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2319;\n    float param_5 = _2319 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2337, 3.0)) * 0.5) / _2319;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2797 = int(fa_shadows[25].x + 0.5);\n    if (_2797 < 1)\n    {\n        return 1.0;\n    }\n    float _2812 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2797 - 1;\n    if (_2812 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2824 = _2797 > 1;\n    bool _2831;\n    if (_2824)\n    {\n        _2831 = _2812 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2831 = _2824;\n    }\n    if (_2831)\n    {\n        ci = 1;\n    }\n    bool _2835 = _2797 > 2;\n    bool _2842;\n    if (_2835)\n    {\n        _2842 = _2812 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2842 = _2835;\n    }\n    if (_2842)\n    {\n        ci = 2;\n    }\n    bool _2846 = _2797 > 3;\n    bool _2853;\n    if (_2846)\n    {\n        _2853 = _2812 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2853 = _2846;\n    }\n    if (_2853)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2797)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2879 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2879;\n        if (_2879 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2904;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2904 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2904 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2923 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2904, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2934 = clamp((_2812 - (fa_shadow_split_at(param_7) - _2923)) / _2923, 0.0, 1.0);\n        if (_2934 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2797)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2955 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2955;\n                if (_2955 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2934);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2477 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2484;\n    if (!_2477)\n    {\n        _2484 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2484 = _2477;\n    }\n    if (_2484)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2497 = fa_light_texel(param);\n    float _2498 = _2497.x;\n    if (_2498 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2507 = int(_2498 + 0.5);\n    int param_1 = _2507;\n    vec4 _2511 = fa_light_texel(param_1);\n    int param_2 = _2507 + 1;\n    vec4 _2516 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2519 = _2511.y;\n    if (_2519 > 0.0)\n    {\n        float _2536 = 1.0 - smoothstep(0.75 * _2519, _2519, length(world - fa_shadows[27].xyz));\n        fade = _2536;\n        if (_2536 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2511.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2560 = (_2507 + 2) + (face * 6);\n    int param_4 = _2560;\n    int param_5 = _2560 + 1;\n    int param_6 = _2560 + 3;\n    vec4 _2574 = fa_light_texel(param_6);\n    int param_7 = _2560 + 4;\n    vec4 _2579 = fa_light_texel(param_7);\n    int param_8 = _2560 + 5;\n    vec4 _2584 = fa_light_texel(param_8);\n    float _2596 = _2584.x * max(dot(_2574, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2601 = clamp(dot(n, l), 0.0, 1.0);\n    float _2624 = clamp(dot(n, _2574.xyz), -1.0, 1.0);\n    float _2643 = min(sqrt(1.0 - (_2624 * _2624)) / max(abs(dot(n, world - lpos)) / max(dot(_2574, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2646 = _2516.y;\n    float _2648;\n    if (_2646 > 0.0)\n    {\n        _2648 = _2646;\n    }\n    else\n    {\n        _2648 = 1.5 * _2596;\n    }\n    vec4 _2668 = vec4(world + (n * (_2648 * sqrt(1.0 - (_2601 * _2601)))), 1.0);\n    float _2672 = dot(_2574, _2668);\n    float _2675 = _2584.y;\n    if (_2672 < _2675)\n    {\n        return 1.0;\n    }\n    vec2 _2690 = vec2(dot(fa_light_texel(param_4), _2668), dot(fa_light_texel(param_5), _2668)) / vec2(_2672);\n    float _2692 = _2690.x;\n    bool _2695 = _2692 < _2579.x;\n    bool _2704;\n    if (!_2695)\n    {\n        _2704 = _2692 > _2579.z;\n    }\n    else\n    {\n        _2704 = _2695;\n    }\n    bool _2713;\n    if (!_2704)\n    {\n        _2713 = _2690.y < _2579.y;\n    }\n    else\n    {\n        _2713 = _2704;\n    }\n    bool _2722;\n    if (!_2713)\n    {\n        _2722 = _2690.y > _2579.w;\n    }\n    else\n    {\n        _2722 = _2713;\n    }\n    if (_2722)\n    {\n        return 1.0;\n    }\n    float _2728 = _2516.x;\n    float _2730;\n    if (_2728 > 0.0)\n    {\n        _2730 = _2728;\n    }\n    else\n    {\n        _2730 = 1.5 * _2596;\n    }\n    vec2 param_9 = _2690;\n    vec4 param_10 = _2579;\n    float param_11 = _2672 - (_2730 * (1.0 + (0.5 * _2643)));\n    float param_12 = _2596;\n    float param_13 = 1.0;\n    float param_14 = _2584.z * 0.25;\n    float param_15 = (_2596 * min(_2643, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2675, _2584.z);\n    int param_17 = int(_2511.z + 0.5);\n    float param_18 = _2511.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3236 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3243;\n    if (!_3236)\n    {\n        _3243 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3243 = _3236;\n    }\n    if (_3243)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3256 = fa_light_texel(param);\n    float _3257 = _3256.y;\n    float len = _3257;\n    if (_3257 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3269 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3279 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3269);\n    if (_3279 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3285 = len;\n    float _3288 = min(_3285, 0.89999997615814208984375 * dist);\n    len = _3288;\n    float _3294 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3269);\n    float _3299 = _3294 + (0.5 * _3288);\n    vec3 _3305 = world + (gn * _3294);\n    float _3307 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3372;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3323 = (float(k) + _3307) * 0.083333335816860198974609375;\n        vec3 _3331 = _3305 + (l * (_3323 * len));\n        vec4 _3337 = vec4(_3331, 1.0);\n        float _3343 = dot(fa_mesh_fs_params[28], _3337);\n        if (_3343 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3363 = vec2(dot(fa_mesh_fs_params[26], _3337), dot(fa_mesh_fs_params[27], _3337)) / vec2(_3343);\n        float _3367 = _3363.x * 0.5;\n        float _3368 = _3367 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3372 = (_3363.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3372 = 0.5 - (_3363.y * 0.5);\n        }\n        bool _3388 = _3368 < 0.0;\n        bool _3395;\n        if (!_3388)\n        {\n            _3395 = _3368 >= 1.0;\n        }\n        else\n        {\n            _3395 = _3388;\n        }\n        bool _3402;\n        if (!_3395)\n        {\n            _3402 = _3372 < 0.0;\n        }\n        else\n        {\n            _3402 = _3395;\n        }\n        bool _3409;\n        if (!_3402)\n        {\n            _3409 = _3372 >= 1.0;\n        }\n        else\n        {\n            _3409 = _3402;\n        }\n        if (_3409)\n        {\n            break;\n        }\n        vec4 _3428 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_3368, _3372) * fa_mesh_fs_params[24].zw), 0);\n        if (_3428.w < 0.5)\n        {\n            continue;\n        }\n        float _3447 = (dot(fa_mesh_fs_params[29].xyz, _3331) + fa_mesh_fs_params[29].w) - _3428.x;\n        if ((_3447 > _3294) && (_3447 < _3299))\n        {\n            occ = max(occ, (1.0 - (_3323 * _3323)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3368, 0.5 - _3367), min(_3372, 1.0 - _3372))));\n        }\n    }\n    return 1.0 - (occ * _3279);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3523 = fa_lm.z > 0.5;\n    bool _3529;\n    if (_3523)\n    {\n        int param = li;\n        _3529 = fa_light_baked(param);\n    }\n    else\n    {\n        _3529 = _3523;\n    }\n    if (_3529)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3553 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _4601 = _3553.color;\n    float _4603 = _3553.shadow;\n    bool _3556 = _3553.type == 0;\n    if (_3556 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3553.direction;\n        float _3567 = fa_shadow_factor(param_5, param_6);\n        _4603 = _3567;\n        _4601 *= _3567;\n    }\n    else\n    {\n        bool _3578 = _3553.type != 0;\n        bool _3584;\n        if (_3578)\n        {\n            _3584 = _3553.attenuation > 0.0;\n        }\n        else\n        {\n            _3584 = _3578;\n        }\n        if (_3584)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3553.direction;\n            float _3603 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4603 = _3603;\n            _4601 *= _3603;\n        }\n    }\n    bool _3613 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3619;\n    if (_3613)\n    {\n        _3619 = _3553.attenuation > 0.0;\n    }\n    else\n    {\n        _3619 = _3613;\n    }\n    if (_3619)\n    {\n        float _3626;\n        if (_3556)\n        {\n            _3626 = 1000000000.0;\n        }\n        else\n        {\n            _3626 = _3553._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _3553.direction;\n        float param_18 = _3626;\n        float _3644 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _4603 *= _3644;\n        _4601 *= _3644;\n    }\n    return LightSample(_3553.direction, _4601, _3553.attenuation, _4603, _3553._distance, _3553.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2979 = int(fa_shadows[25].x + 0.5);\n    float _2989 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2994 = _2979 > 0;\n    bool _3003;\n    if (_2994)\n    {\n        int param = _2979 - 1;\n        _3003 = _2989 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3003 = _2994;\n    }\n    if (_3003)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3009 = _2979 > 1;\n        bool _3016;\n        if (_3009)\n        {\n            _3016 = _2989 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3016 = _3009;\n        }\n        if (_3016)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3022 = _2979 > 2;\n        bool _3029;\n        if (_3022)\n        {\n            _3029 = _2989 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3029 = _3022;\n        }\n        if (_3029)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3035 = _2979 > 3;\n        bool _3042;\n        if (_3035)\n        {\n            _3042 = _2989 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3042 = _3035;\n        }\n        if (_3042)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4442 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4442 = -_4442;\n    }\n    vec3 _4028 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4442, fa_world_tangent, fa_uv, fa_vertex_color, _4028, gl_FrontFacing);\n    Surface _4036 = fa_standard_surface(param_1);\n    vec3 _4473 = _4036.albedo;\n    float _4474 = _4036.alpha;\n    vec3 _4475 = _4036.normal;\n    float _4476 = _4036.metallic;\n    float _4477 = _4036.roughness;\n    float _4478 = _4036.occlusion;\n    vec3 _4479 = _4036.emission;\n    float _4480 = _4036.clearcoat;\n    float _4481 = _4036.clearcoat_roughness;\n    vec3 _4482 = _4036.sheen_color;\n    float _4483 = _4036.sheen_roughness;\n    float _4484 = _4036.anisotropy;\n    float _4485 = _4036.anisotropy_rotation;\n    float _4486 = _4036.specular;\n    float _4487 = _4036.ior;\n    vec3 _4488 = _4036.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4442, fa_world_tangent, fa_uv, fa_vertex_color, _4028, gl_FrontFacing);\n    Surface param_3 = _4036;\n    surface(param_2, param_3);\n    _4473 = param_3.albedo;\n    _4474 = param_3.alpha;\n    _4475 = param_3.normal;\n    _4476 = param_3.metallic;\n    _4477 = param_3.roughness;\n    _4478 = param_3.occlusion;\n    _4479 = param_3.emission;\n    _4480 = param_3.clearcoat;\n    _4481 = param_3.clearcoat_roughness;\n    _4482 = param_3.sheen_color;\n    _4483 = param_3.sheen_roughness;\n    _4484 = param_3.anisotropy;\n    _4485 = param_3.anisotropy_rotation;\n    _4486 = param_3.specular;\n    _4487 = param_3.ior;\n    _4488 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4442;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4473 = param_6;\n    _4475 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4473;\n    }\n    else\n    {\n        vec3 _4074 = _4475;\n        vec3 _4075 = normalize(_4074);\n        _4475 = _4075;\n        vec3 param_8 = _4075;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _4473) * _4478;\n        int _4094 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4094; ln++)\n        {\n            int param_9 = ln;\n            int _4107 = fa_cl_light(param_9);\n            bool _4110 = fa_lm.z > 0.5;\n            bool _4116;\n            if (_4110)\n            {\n                int param_10 = _4107;\n                _4116 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _4116 = _4110;\n            }\n            if (_4116)\n            {\n                continue;\n            }\n            int param_11 = _4107;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _4442;\n            LightSample _4128 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _4442, fa_world_tangent, fa_uv, fa_vertex_color, _4028, gl_FrontFacing);\n            Surface param_15 = Surface(_4473, _4474, _4475, _4476, _4477, _4478, _4479, _4480, _4481, _4482, _4483, _4484, _4485, _4486, _4487, _4488);\n            LightSample param_16 = _4128;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _4143 = result;\n    vec3 _4144 = _4143 + _4479;\n    result = _4144;\n    vec3 param_17 = _4144;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _4153 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4160;\n    if (!_4153)\n    {\n        _4160 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4160 = _4153;\n    }\n    if (_4160)\n    {\n        vec3 _4169 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4175 = dot(_4169, fa_mesh_fs_params[9].xyz);\n        bool _4179 = fa_mesh_fs_params[9].w > 0.5;\n        float _4180;\n        if (_4179)\n        {\n            _4180 = _4175;\n        }\n        else\n        {\n            _4180 = length(_4169);\n        }\n        float _4192 = _4180 - fa_mesh_fs_params[8].x;\n        if (_4192 > 0.0)\n        {\n            float _4201 = fa_mesh_fs_params[7].w * _4192;\n            float tau = _4201 * _4201;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4217;\n                if (_4179)\n                {\n                    _4217 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4175);\n                }\n                else\n                {\n                    _4217 = fa_mesh_fs_params[0].y;\n                }\n                float _4238 = mix(_4217, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4180, 0.0, 1.0));\n                float _4242 = fa_world_pos.y - _4238;\n                float _4247 = _4238 - fa_mesh_fs_params[8].z;\n                float _4252 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4255 = _4247 <= 0.0;\n                bool _4256 = !_4255;\n                bool _4262;\n                if (_4256)\n                {\n                    _4262 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4262 = _4255;\n                }\n                float _4263;\n                if (_4262)\n                {\n                    _4263 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4263 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4247, 80.0));\n                }\n                bool _4290;\n                if (_4256)\n                {\n                    _4290 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4290 = _4255;\n                }\n                float _4291;\n                if (_4290)\n                {\n                    _4291 = fa_mesh_fs_params[8].y * _4247;\n                }\n                else\n                {\n                    _4291 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4247, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4316 = _4252 <= 0.0;\n                bool _4323;\n                if (!_4316)\n                {\n                    _4323 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4323 = _4316;\n                }\n                float _4324;\n                if (_4323)\n                {\n                    _4324 = fa_mesh_fs_params[8].y * _4252;\n                }\n                else\n                {\n                    _4324 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4252, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4351;\n                if (abs(_4242) < 0.001000000047497451305389404296875)\n                {\n                    _4351 = _4263;\n                }\n                else\n                {\n                    _4351 = (_4324 - _4291) / _4242;\n                }\n                tau += (_4192 * max(_4351, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4474);\n}\n\n",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_386",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
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
            "inst_name": "_2043",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[30];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1314 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1321;\n    if (!_1314)\n    {\n        _1321 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1321 = _1314;\n    }\n    bool _1329;\n    if (!_1321)\n    {\n        _1329 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1329 = _1321;\n    }\n    bool _1336;\n    if (!_1329)\n    {\n        _1336 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1336 = _1329;\n    }\n    bool _1343;\n    if (!_1336)\n    {\n        _1343 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1343 = _1336;\n    }\n    if (_1343)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1353 = vec4(world_pos, 1.0);\n    float _1359 = dot(fa_mesh_fs_params[16], _1353);\n    if (!(_1359 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1381 = vec2(dot(fa_mesh_fs_params[14], _1353), dot(fa_mesh_fs_params[15], _1353)) / vec2(_1359);\n    int _1385 = int(fa_mesh_fs_params[18].x);\n    int _1389 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1389) + clamp(int(floor(((_1381.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1389 - 1)) * _1385)) + clamp(int(floor(((_1381.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1385 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1465 = fa_cluster_texel(param);\n    return ivec2(int(_1465.x), int(_1465.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3496 = fa_cluster_lookup(param);\n    fa_cl_slot = _3496.x;\n    fa_cl_local = _3496.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3696 = fa_linear_to_srgb(param);\n        c = _3696;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3704 = fa_srgb_to_linear(param_1);\n            c = _3704;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _269;\n    if (i.front_facing)\n    {\n        _269 = i.world_normal;\n    }\n    else\n    {\n        _269 = -i.world_normal;\n    }\n    vec3 _293 = normalize(i.world_tangent.xyz - (_269 * dot(_269, i.world_tangent.xyz)));\n    vec3 _320 = normalize(((_293 * m.x) + ((cross(_269, _293) * i.world_tangent.w) * m.y)) + (_269 * m.z));\n    vec3 _323;\n    if (i.front_facing)\n    {\n        _323 = _320;\n    }\n    else\n    {\n        _323 = -_320;\n    }\n    return _323;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3735 = fa_tex_fix(param_2, param_3);\n    vec4 _4769 = base_t;\n    _4769.x = _3735.x;\n    _4769.y = _3735.y;\n    _4769.z = _3735.z;\n    base_t = _4769;\n    vec4 _3749 = (_4769 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4621 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3781 = fa_tex_fix(param_6, param_7);\n        vec3 _3784 = (_3781 * 2.0) - vec3(1.0);\n        vec2 _3789 = _3784.xy * fa_mesh_fs_params[6].x;\n        vec3 _4777 = _3784;\n        _4777.x = _3789.x;\n        _4777.y = _3789.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4777;\n        _4621 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3817 = fa_tex_fix(param_12, param_13);\n    vec4 _4780 = mrt;\n    _4780.x = _3817.x;\n    _4780.y = _3817.y;\n    _4780.z = _3817.z;\n    mrt = _4780;\n    vec4 _3845 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3845.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3856 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3886 = fa_tex_fix(param_20, param_21);\n    float _4626 = fa_mesh_fs_params[20].x;\n    float _4627 = fa_mesh_fs_params[20].y;\n    float _4630 = fa_mesh_fs_params[20].z;\n    float _4629 = fa_mesh_fs_params[21].w;\n    float _4632 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4626 *= _3856.y;\n            _4627 *= _3856.z;\n            _4629 *= _3845.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4630 *= mrt.x;\n            _4632 *= mrt.w;\n        }\n    }\n    return Surface(_3749.xyz, _3749.w, _4621, clamp(fa_mesh_fs_params[5].x * _3817.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3817.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3856.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3886), _4626, _4627, fa_mesh_fs_params[21].xyz, _4629, _4630, fa_mesh_fs_params[20].w, _4632, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1545 = rect.zw - rect.xy;\n    vec2 _1549 = _1545 * atlas;\n    vec2 _1553 = ddx * _1549;\n    vec2 _1557 = ddy * _1549;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1545), clamp(0.5 * log2(max(max(dot(_1553, _1553), dot(_1557, _1557)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1590 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1597;\n    if (!_1590)\n    {\n        _1597 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1597 = _1590;\n    }\n    if (_1597)\n    {\n        return;\n    }\n    vec3 _1603 = dFdx(world_pos);\n    vec3 _1606 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1610 = fa_cluster_texel(param);\n    int _1614 = int(_1610.w);\n    if (_1614 < 1)\n    {\n        return;\n    }\n    int _1624 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1624;\n    vec4 _1628 = fa_light_texel(param_1);\n    vec2 _1631 = _1628.yz;\n    int _1635 = int(_1628.w);\n    int param_2 = _1624 + 1;\n    vec4 _1640 = fa_light_texel(param_2);\n    float _1641 = _1640.x;\n    int _1647 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1651 = int(_1610.z);\n    vec3 _1916;\n    for (int k = 0; k < _1614; k++)\n    {\n        int _1664 = _1651 + k;\n        int param_3 = _1635 + (_1664 >> 2);\n        int _1681 = (_1624 + 2) + (int(fa_light_texel(param_3)[_1664 & 3]) * 7);\n        int param_4 = _1681 + 6;\n        vec4 _1686 = fa_light_texel(param_4);\n        if (((int(_1686.w + 0.5) >> _1647) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1681;\n        vec4 _1701 = fa_light_texel(param_5);\n        int param_6 = _1681 + 1;\n        vec4 _1706 = fa_light_texel(param_6);\n        int param_7 = _1681 + 2;\n        vec4 _1711 = fa_light_texel(param_7);\n        vec3 _1714 = _1701.xyz;\n        float _1719 = dot(_1714, world_pos) + _1701.w;\n        vec3 _1721 = _1706.xyz;\n        float _1726 = dot(_1721, world_pos) + _1706.w;\n        vec3 _1728 = _1711.xyz;\n        float _1733 = dot(_1728, world_pos) + _1711.w;\n        bool _1738 = abs(_1719) > 0.5;\n        bool _1746;\n        if (!_1738)\n        {\n            _1746 = abs(_1726) > 0.5;\n        }\n        else\n        {\n            _1746 = _1738;\n        }\n        bool _1754;\n        if (!_1746)\n        {\n            _1754 = abs(_1733) > 0.5;\n        }\n        else\n        {\n            _1754 = _1746;\n        }\n        if (_1754)\n        {\n            continue;\n        }\n        float _1769 = clamp(dot(geo_normal, normalize(_1728)) * _1686.z, 0.0, 1.0);\n        if (_1769 <= 0.0)\n        {\n            continue;\n        }\n        float _1789 = (clamp((0.5 - abs(_1733)) * 10.0, 0.0, 1.0) * _1769) * _1686.x;\n        vec2 _1797 = vec2(_1719 + 0.5, 0.5 - _1726);\n        vec2 _1807 = vec2(dot(_1714, _1603), dot(_1721, _1603));\n        vec2 _1817 = vec2(dot(_1714, _1606), dot(_1721, _1606));\n        int param_8 = _1681 + 5;\n        vec4 _1822 = fa_light_texel(param_8);\n        int param_9 = _1681 + 3;\n        vec4 _1827 = fa_light_texel(param_9);\n        int param_10 = _1681 + 4;\n        vec4 _1832 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1822.xyz;\n        bool _1842 = _1827.z > _1827.x;\n        if (_1842)\n        {\n            vec4 param_11 = _1827;\n            vec2 param_12 = _1797;\n            vec2 param_13 = _1631;\n            vec2 param_14 = _1807;\n            vec2 param_15 = _1817;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1641 > 0.5) && (_1641 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1868 = fa_dc_to_linear(param_16);\n                vec4 _4701 = tx;\n                _4701.x = _1868.x;\n                _4701.y = _1868.y;\n                _4701.z = _1868.z;\n                tx = _4701;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1789 * tex_a) * _1822.w, 0.0, 1.0)));\n        if (_1832.z > _1832.x)\n        {\n            vec4 param_17 = _1832;\n            vec2 param_18 = _1797;\n            vec2 param_19 = _1631;\n            vec2 param_20 = _1807;\n            vec2 param_21 = _1817;\n            vec4 _1912 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1641 > 1.5)\n            {\n                vec3 param_22 = _1912.xyz;\n                vec3 _1922 = fa_dc_to_srgb(param_22);\n                _1916 = _1922;\n            }\n            else\n            {\n                _1916 = _1912.xyz;\n            }\n            vec3 _1931 = (_1916 * 2.0) - vec3(1.0);\n            vec2 _1936 = _1931.xy * _1686.y;\n            vec3 _1958 = (normalize(_1714) * _1936.x) + (normalize(_1721) * _1936.y);\n            vec3 _1961 = normalize(normal);\n            normal = normalize(mix(_1961, normalize((_1961 * max(_1931.z, 0.0500000007450580596923828125)) + (_1958 - (_1961 * dot(_1961, _1958)))), vec3(clamp(_1789 * (_1842 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3156 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3156;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _564 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _577 = (c - (ru * hx)) - p;\n        vec3 _583 = ru * (2.0 * hx);\n        float _589 = max(dot(_583, _583), 9.9999999392252902907785028219223e-09);\n        float _593 = dot(_577, _583);\n        float t = clamp((-_593) / _589, 0.0, 1.0);\n        if (_564)\n        {\n            float _608 = dot(r, _583);\n            float _614 = _589 - (_608 * _608);\n            if (abs(_614) > (9.9999997473787516355514526367188e-06 * _589))\n            {\n                t = clamp(((dot(r, _577) * _608) - _593) / _614, 0.0, 1.0);\n            }\n        }\n        return (p + _577) + (_583 * t);\n    }\n    vec3 q = p;\n    float _646 = dot(r, axis);\n    bool _654;\n    if (_564)\n    {\n        _654 = abs(_646) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _654 = _564;\n    }\n    if (_654)\n    {\n        float _664 = dot(c - p, axis) / _646;\n        if (_664 > 0.0)\n        {\n            q = p + (r * _664);\n        }\n    }\n    vec3 _677 = q - c;\n    vec2 xy = vec2(dot(_677, ru), dot(_677, uu));\n    if (shape > 0.5)\n    {\n        float _692 = length(xy);\n        if (_692 > hx)\n        {\n            xy *= (hx / _692);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _335 = abs(d);\n    float _337 = _335.x;\n    float _339 = _335.y;\n    bool _340 = _337 >= _339;\n    bool _348;\n    if (_340)\n    {\n        _348 = _337 >= _335.z;\n    }\n    else\n    {\n        _348 = _340;\n    }\n    int _349;\n    if (_348)\n    {\n        _349 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _364;\n        if (_339 >= _335.z)\n        {\n            _364 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _364 = (d.z > 0.0) ? 4 : 5;\n        }\n        _349 = _364;\n    }\n    return _349;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _484 = dot(d, right);\n    float _488 = dot(d, up);\n    float _499;\n    if (((_484 * _484) + (_488 * _488)) > 1.0000000133514319600180897396058e-10)\n    {\n        _499 = atan(_488, _484) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _499 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_499 - floor(_499)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _730 = fa_light_base(param);\n    bool _734 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _730;\n    vec4 _738 = fa_light_texel(param_1);\n    int param_2 = _730 + 1;\n    vec4 _743 = fa_light_texel(param_2);\n    float _746 = _743.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _758 = _734 && (_746 > 2.5);\n    fa_light_is_area = _758;\n    bool _760 = _746 < 0.5;\n    vec3 l;\n    if (_760)\n    {\n        l = normalize(_738.xyz);\n        if (_734)\n        {\n            int param_3 = _730 + 6;\n            vec4 _774 = fa_light_texel(param_3);\n            if (_774.z > 0.5)\n            {\n                int param_4 = _730 + 4;\n                vec4 _784 = fa_light_texel(param_4);\n                int param_5 = _730 + 5;\n                vec4 _789 = fa_light_texel(param_5);\n                vec2 param_6 = _774.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _784.xyz) * _784.w, (-dot(world_pos, _789.xyz)) * _789.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _819 = _738.xyz;\n        vec3 _821 = _819 - world_pos;\n        vec3 to_light = _821;\n        float _824 = length(_821);\n        float reach = _824;\n        bool front = true;\n        if (_758)\n        {\n            int param_8 = _730 + 7;\n            reach = max(_824 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _730 + 4;\n            vec4 _848 = fa_light_texel(param_9);\n            int param_10 = _730 + 5;\n            vec4 _853 = fa_light_texel(param_10);\n            int param_11 = _730 + 6;\n            vec4 _858 = fa_light_texel(param_11);\n            float _859 = _858.w;\n            int param_12 = _730 + 2;\n            vec3 _866 = normalize(fa_light_texel(param_12).xyz);\n            bool _868 = _859 > 1.5;\n            bool _876;\n            if (!_868)\n            {\n                _876 = dot(_866, to_light) < 0.0;\n            }\n            else\n            {\n                _876 = _868;\n            }\n            front = _876;\n            vec3 r = vec3(0.0);\n            vec3 _885 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _889 = dot(n, n) > 0.5;\n            bool _897;\n            if (_889)\n            {\n                _897 = dot(_885, _885) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _897 = _889;\n            }\n            if (_897)\n            {\n                r = reflect(-normalize(_885), normalize(n));\n            }\n            vec3 param_13 = _819;\n            vec3 param_14 = _866;\n            vec3 param_15 = _848.xyz;\n            vec3 param_16 = _853.xyz;\n            float param_17 = _848.w;\n            float param_18 = _853.w;\n            float param_19 = _859;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _933 = length(to_light);\n        dist = _933;\n        l = to_light / vec3(max(_933, 9.9999997473787516355514526367188e-05));\n        float _947 = reach / max(_738.w, 0.001000000047497451305389404296875);\n        float _953 = clamp(1.0 - (_947 * _947), 0.0, 1.0);\n        float _955;\n        if (front)\n        {\n            _955 = _953 * _953;\n        }\n        else\n        {\n            _955 = 0.0;\n        }\n        atten = _955;\n        bool _966 = _746 < 2.5;\n        if ((_746 > 1.5) && _966)\n        {\n            int param_22 = _730 + 2;\n            vec4 _974 = fa_light_texel(param_22);\n            float _984 = _974.w;\n            int param_23 = _730 + 3;\n            vec4 _989 = fa_light_texel(param_23);\n            float _990 = _989.x;\n            float cos_inner = _990;\n            if (_990 > 1.5)\n            {\n                cos_inner = mix(_984, 1.0, 0.25);\n            }\n            atten *= smoothstep(_984, cos_inner, dot(-l, normalize(_974.xyz)));\n        }\n        if (_734 && (_746 < 1.5))\n        {\n            int param_24 = _730 + 6;\n            vec4 _1014 = fa_light_texel(param_24);\n            if (_1014.z > 0.5)\n            {\n                vec3 _1022 = -to_light;\n                int param_25 = _730 + 4;\n                int param_26 = _730 + 5;\n                vec3 _1036 = fa_light_texel(param_25).xyz;\n                vec3 _1040 = fa_light_texel(param_26).xyz;\n                vec3 _1049 = vec3(dot(_1022, _1036), dot(_1022, _1040), dot(_1022, cross(_1036, _1040)));\n                vec3 param_27 = _1049;\n                int _1053 = fa_cube_face(param_27);\n                int param_28 = _1053;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1080 = vec2(dot(_1049, cross(param_29, param_30)), dot(_1049, param_30)) / vec2(max(dot(_1049, param_29), 9.9999997473787516355514526367188e-05));\n                int _1084 = _1053 / 3;\n                vec2 param_31 = _1014.xy + (vec2(float(_1053 - (_1084 * 3)), float(_1084)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1080.x), 0.5 - (0.5 * _1080.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _730 + 7;\n            vec4 _1114 = fa_light_texel(param_33);\n            if (_1114.z > 0.5)\n            {\n                int param_34 = _730 + 2;\n                int param_35 = _730 + 4;\n                int param_36 = _730 + 5;\n                vec2 param_37 = _1114.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_734 && _966)\n            {\n                int param_42 = _730 + 6;\n                vec4 _1161 = fa_light_texel(param_42);\n                int param_43 = _730 + 7;\n                vec4 _1166 = fa_light_texel(param_43);\n                bool _1169 = _1161.z > 0.5;\n                bool _1176;\n                if (!_1169)\n                {\n                    _1176 = _1166.z > 0.5;\n                }\n                else\n                {\n                    _1176 = _1169;\n                }\n                if (_1176)\n                {\n                    int param_44 = _730 + 2;\n                    vec4 _1183 = fa_light_texel(param_44);\n                    vec3 _1187 = normalize(_1183.xyz);\n                    int param_45 = _730 + 4;\n                    vec4 _1192 = fa_light_texel(param_45);\n                    int param_46 = _730 + 5;\n                    vec4 _1197 = fa_light_texel(param_46);\n                    if (_1169)\n                    {\n                        vec3 _1205 = -to_light;\n                        float _1212 = _1183.w;\n                        float _1228 = 0.5 / max(dot(_1205, _1187) * (sqrt(max(1.0 - (_1212 * _1212), 0.0)) / max(_1212, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1161.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1205, _1192.xyz) * _1228), 0.5 - (dot(_1205, _1197.xyz) * _1228));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1166.z > 0.5)\n                    {\n                        vec2 param_49 = _1166.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1187;\n                        vec3 param_52 = _1192.xyz;\n                        vec3 param_53 = _1197.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _4575 = _743.xyz * atten;\n    if (_734)\n    {\n        _4575 *= fa_light_tint;\n    }\n    int _1296;\n    if (_760)\n    {\n        _1296 = 0;\n    }\n    else\n    {\n        _1296 = ((_746 > 1.5) && (_746 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4575, atten, 1.0, dist, _1296);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2033;\n    if (i == 0)\n    {\n        _2033 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2049;\n        if (i == 1)\n        {\n            _2049 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2057;\n            if (i == 2)\n            {\n                _2057 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2057 = fa_shadows[24].w;\n            }\n            _2049 = _2057;\n        }\n        _2033 = _2049;\n    }\n    return _2033;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2090 = fa_shadow_depth(param, param_1);\n    float _2094;\n    if (conv.x < 0.5)\n    {\n        _2094 = _2090;\n    }\n    else\n    {\n        _2094 = (conv.y * conv.z) / (conv.z - (_2090 * (conv.z - conv.y)));\n    }\n    return _2094;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2021 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2021), sin(_2021)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2140 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2149;\n        if (k < 0.0)\n        {\n            _2149 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2149 = k;\n        }\n        float _2169 = clamp((_2149 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2140;\n            vec2 _2188 = fa_shadow_vogel(param_3, param_4, param_5) * _2169;\n            vec2 param_6 = uv + (_2188 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2200 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2200 < (zr - (length(_2188) * plane)))\n            {\n                sum += _2200;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2226 = sum / cnt;\n        float _2236;\n        if (k < 0.0)\n        {\n            _2236 = (-k) / max(_2226, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2236 = k;\n        }\n        radius = clamp(((max(zr - _2226, 0.0) * unit) * _2236) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2258 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2258; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2258;\n        float param_11 = _2140;\n        vec2 _2277 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2277 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2277) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2258);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2319 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2324 = clamp(dot(n, l), 0.0, 1.0);\n    float _2330 = sqrt(1.0 - (_2324 * _2324));\n    float _2337 = min(_2330 / max(_2324, 0.20000000298023223876953125), 4.0);\n    float _2342;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2342 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2342 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2367 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2342 * _2330)), 1.0);\n    float _2374 = _2367.x;\n    bool _2377 = _2374 < fa_shadows[ci * 1 + 16].x;\n    bool _2386;\n    if (!_2377)\n    {\n        _2386 = _2374 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2386 = _2377;\n    }\n    bool _2395;\n    if (!_2386)\n    {\n        _2395 = _2367.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2395 = _2386;\n    }\n    bool _2404;\n    if (!_2395)\n    {\n        _2404 = _2367.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2404 = _2395;\n    }\n    bool _2411;\n    if (!_2404)\n    {\n        _2411 = _2367.z > 1.0;\n    }\n    else\n    {\n        _2411 = _2404;\n    }\n    if (_2411)\n    {\n        return -1.0;\n    }\n    float _2419;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2419 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2419 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2367.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2367.z - ((_2419 * (1.0 + (0.5 * _2337))) / _2319);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2319;\n    float param_5 = _2319 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2337, 3.0)) * 0.5) / _2319;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2797 = int(fa_shadows[25].x + 0.5);\n    if (_2797 < 1)\n    {\n        return 1.0;\n    }\n    float _2812 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2797 - 1;\n    if (_2812 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2824 = _2797 > 1;\n    bool _2831;\n    if (_2824)\n    {\n        _2831 = _2812 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2831 = _2824;\n    }\n    if (_2831)\n    {\n        ci = 1;\n    }\n    bool _2835 = _2797 > 2;\n    bool _2842;\n    if (_2835)\n    {\n        _2842 = _2812 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2842 = _2835;\n    }\n    if (_2842)\n    {\n        ci = 2;\n    }\n    bool _2846 = _2797 > 3;\n    bool _2853;\n    if (_2846)\n    {\n        _2853 = _2812 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2853 = _2846;\n    }\n    if (_2853)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2797)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2879 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2879;\n        if (_2879 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2904;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2904 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2904 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2923 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2904, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2934 = clamp((_2812 - (fa_shadow_split_at(param_7) - _2923)) / _2923, 0.0, 1.0);\n        if (_2934 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2797)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2955 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2955;\n                if (_2955 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2934);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2477 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2484;\n    if (!_2477)\n    {\n        _2484 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2484 = _2477;\n    }\n    if (_2484)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2497 = fa_light_texel(param);\n    float _2498 = _2497.x;\n    if (_2498 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2507 = int(_2498 + 0.5);\n    int param_1 = _2507;\n    vec4 _2511 = fa_light_texel(param_1);\n    int param_2 = _2507 + 1;\n    vec4 _2516 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2519 = _2511.y;\n    if (_2519 > 0.0)\n    {\n        float _2536 = 1.0 - smoothstep(0.75 * _2519, _2519, length(world - fa_shadows[27].xyz));\n        fade = _2536;\n        if (_2536 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2511.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2560 = (_2507 + 2) + (face * 6);\n    int param_4 = _2560;\n    int param_5 = _2560 + 1;\n    int param_6 = _2560 + 3;\n    vec4 _2574 = fa_light_texel(param_6);\n    int param_7 = _2560 + 4;\n    vec4 _2579 = fa_light_texel(param_7);\n    int param_8 = _2560 + 5;\n    vec4 _2584 = fa_light_texel(param_8);\n    float _2596 = _2584.x * max(dot(_2574, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2601 = clamp(dot(n, l), 0.0, 1.0);\n    float _2624 = clamp(dot(n, _2574.xyz), -1.0, 1.0);\n    float _2643 = min(sqrt(1.0 - (_2624 * _2624)) / max(abs(dot(n, world - lpos)) / max(dot(_2574, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2646 = _2516.y;\n    float _2648;\n    if (_2646 > 0.0)\n    {\n        _2648 = _2646;\n    }\n    else\n    {\n        _2648 = 1.5 * _2596;\n    }\n    vec4 _2668 = vec4(world + (n * (_2648 * sqrt(1.0 - (_2601 * _2601)))), 1.0);\n    float _2672 = dot(_2574, _2668);\n    float _2675 = _2584.y;\n    if (_2672 < _2675)\n    {\n        return 1.0;\n    }\n    vec2 _2690 = vec2(dot(fa_light_texel(param_4), _2668), dot(fa_light_texel(param_5), _2668)) / vec2(_2672);\n    float _2692 = _2690.x;\n    bool _2695 = _2692 < _2579.x;\n    bool _2704;\n    if (!_2695)\n    {\n        _2704 = _2692 > _2579.z;\n    }\n    else\n    {\n        _2704 = _2695;\n    }\n    bool _2713;\n    if (!_2704)\n    {\n        _2713 = _2690.y < _2579.y;\n    }\n    else\n    {\n        _2713 = _2704;\n    }\n    bool _2722;\n    if (!_2713)\n    {\n        _2722 = _2690.y > _2579.w;\n    }\n    else\n    {\n        _2722 = _2713;\n    }\n    if (_2722)\n    {\n        return 1.0;\n    }\n    float _2728 = _2516.x;\n    float _2730;\n    if (_2728 > 0.0)\n    {\n        _2730 = _2728;\n    }\n    else\n    {\n        _2730 = 1.5 * _2596;\n    }\n    vec2 param_9 = _2690;\n    vec4 param_10 = _2579;\n    float param_11 = _2672 - (_2730 * (1.0 + (0.5 * _2643)));\n    float param_12 = _2596;\n    float param_13 = 1.0;\n    float param_14 = _2584.z * 0.25;\n    float param_15 = (_2596 * min(_2643, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2675, _2584.z);\n    int param_17 = int(_2511.z + 0.5);\n    float param_18 = _2511.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3236 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3243;\n    if (!_3236)\n    {\n        _3243 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3243 = _3236;\n    }\n    if (_3243)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3256 = fa_light_texel(param);\n    float _3257 = _3256.y;\n    float len = _3257;\n    if (_3257 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3269 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3279 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3269);\n    if (_3279 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3285 = len;\n    float _3288 = min(_3285, 0.89999997615814208984375 * dist);\n    len = _3288;\n    float _3294 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3269);\n    float _3299 = _3294 + (0.5 * _3288);\n    vec3 _3305 = world + (gn * _3294);\n    float _3307 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3372;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3323 = (float(k) + _3307) * 0.083333335816860198974609375;\n        vec3 _3331 = _3305 + (l * (_3323 * len));\n        vec4 _3337 = vec4(_3331, 1.0);\n        float _3343 = dot(fa_mesh_fs_params[28], _3337);\n        if (_3343 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3363 = vec2(dot(fa_mesh_fs_params[26], _3337), dot(fa_mesh_fs_params[27], _3337)) / vec2(_3343);\n        float _3367 = _3363.x * 0.5;\n        float _3368 = _3367 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3372 = (_3363.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3372 = 0.5 - (_3363.y * 0.5);\n        }\n        bool _3388 = _3368 < 0.0;\n        bool _3395;\n        if (!_3388)\n        {\n            _3395 = _3368 >= 1.0;\n        }\n        else\n        {\n            _3395 = _3388;\n        }\n        bool _3402;\n        if (!_3395)\n        {\n            _3402 = _3372 < 0.0;\n        }\n        else\n        {\n            _3402 = _3395;\n        }\n        bool _3409;\n        if (!_3402)\n        {\n            _3409 = _3372 >= 1.0;\n        }\n        else\n        {\n            _3409 = _3402;\n        }\n        if (_3409)\n        {\n            break;\n        }\n        vec4 _3428 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_3368, _3372) * fa_mesh_fs_params[24].zw), 0);\n        if (_3428.w < 0.5)\n        {\n            continue;\n        }\n        float _3447 = (dot(fa_mesh_fs_params[29].xyz, _3331) + fa_mesh_fs_params[29].w) - _3428.x;\n        if ((_3447 > _3294) && (_3447 < _3299))\n        {\n            occ = max(occ, (1.0 - (_3323 * _3323)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3368, 0.5 - _3367), min(_3372, 1.0 - _3372))));\n        }\n    }\n    return 1.0 - (occ * _3279);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3523 = fa_lm.z > 0.5;\n    bool _3529;\n    if (_3523)\n    {\n        int param = li;\n        _3529 = fa_light_baked(param);\n    }\n    else\n    {\n        _3529 = _3523;\n    }\n    if (_3529)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3553 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _4601 = _3553.color;\n    float _4603 = _3553.shadow;\n    bool _3556 = _3553.type == 0;\n    if (_3556 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3553.direction;\n        float _3567 = fa_shadow_factor(param_5, param_6);\n        _4603 = _3567;\n        _4601 *= _3567;\n    }\n    else\n    {\n        bool _3578 = _3553.type != 0;\n        bool _3584;\n        if (_3578)\n        {\n            _3584 = _3553.attenuation > 0.0;\n        }\n        else\n        {\n            _3584 = _3578;\n        }\n        if (_3584)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3553.direction;\n            float _3603 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4603 = _3603;\n            _4601 *= _3603;\n        }\n    }\n    bool _3613 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3619;\n    if (_3613)\n    {\n        _3619 = _3553.attenuation > 0.0;\n    }\n    else\n    {\n        _3619 = _3613;\n    }\n    if (_3619)\n    {\n        float _3626;\n        if (_3556)\n        {\n            _3626 = 1000000000.0;\n        }\n        else\n        {\n            _3626 = _3553._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _3553.direction;\n        float param_18 = _3626;\n        float _3644 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _4603 *= _3644;\n        _4601 *= _3644;\n    }\n    return LightSample(_3553.direction, _4601, _3553.attenuation, _4603, _3553._distance, _3553.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2979 = int(fa_shadows[25].x + 0.5);\n    float _2989 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2994 = _2979 > 0;\n    bool _3003;\n    if (_2994)\n    {\n        int param = _2979 - 1;\n        _3003 = _2989 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3003 = _2994;\n    }\n    if (_3003)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3009 = _2979 > 1;\n        bool _3016;\n        if (_3009)\n        {\n            _3016 = _2989 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3016 = _3009;\n        }\n        if (_3016)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3022 = _2979 > 2;\n        bool _3029;\n        if (_3022)\n        {\n            _3029 = _2989 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3029 = _3022;\n        }\n        if (_3029)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3035 = _2979 > 3;\n        bool _3042;\n        if (_3035)\n        {\n            _3042 = _2989 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3042 = _3035;\n        }\n        if (_3042)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4442 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4442 = -_4442;\n    }\n    vec3 _4028 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4442, fa_world_tangent, fa_uv, fa_vertex_color, _4028, gl_FrontFacing);\n    Surface _4036 = fa_standard_surface(param_1);\n    vec3 _4473 = _4036.albedo;\n    float _4474 = _4036.alpha;\n    vec3 _4475 = _4036.normal;\n    float _4476 = _4036.metallic;\n    float _4477 = _4036.roughness;\n    float _4478 = _4036.occlusion;\n    vec3 _4479 = _4036.emission;\n    float _4480 = _4036.clearcoat;\n    float _4481 = _4036.clearcoat_roughness;\n    vec3 _4482 = _4036.sheen_color;\n    float _4483 = _4036.sheen_roughness;\n    float _4484 = _4036.anisotropy;\n    float _4485 = _4036.anisotropy_rotation;\n    float _4486 = _4036.specular;\n    float _4487 = _4036.ior;\n    vec3 _4488 = _4036.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4442, fa_world_tangent, fa_uv, fa_vertex_color, _4028, gl_FrontFacing);\n    Surface param_3 = _4036;\n    surface(param_2, param_3);\n    _4473 = param_3.albedo;\n    _4474 = param_3.alpha;\n    _4475 = param_3.normal;\n    _4476 = param_3.metallic;\n    _4477 = param_3.roughness;\n    _4478 = param_3.occlusion;\n    _4479 = param_3.emission;\n    _4480 = param_3.clearcoat;\n    _4481 = param_3.clearcoat_roughness;\n    _4482 = param_3.sheen_color;\n    _4483 = param_3.sheen_roughness;\n    _4484 = param_3.anisotropy;\n    _4485 = param_3.anisotropy_rotation;\n    _4486 = param_3.specular;\n    _4487 = param_3.ior;\n    _4488 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4442;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4473 = param_6;\n    _4475 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4473;\n    }\n    else\n    {\n        vec3 _4074 = _4475;\n        vec3 _4075 = normalize(_4074);\n        _4475 = _4075;\n        vec3 param_8 = _4075;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _4473) * _4478;\n        int _4094 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4094; ln++)\n        {\n            int param_9 = ln;\n            int _4107 = fa_cl_light(param_9);\n            bool _4110 = fa_lm.z > 0.5;\n            bool _4116;\n            if (_4110)\n            {\n                int param_10 = _4107;\n                _4116 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _4116 = _4110;\n            }\n            if (_4116)\n            {\n                continue;\n            }\n            int param_11 = _4107;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _4442;\n            LightSample _4128 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _4442, fa_world_tangent, fa_uv, fa_vertex_color, _4028, gl_FrontFacing);\n            Surface param_15 = Surface(_4473, _4474, _4475, _4476, _4477, _4478, _4479, _4480, _4481, _4482, _4483, _4484, _4485, _4486, _4487, _4488);\n            LightSample param_16 = _4128;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _4143 = result;\n    vec3 _4144 = _4143 + _4479;\n    result = _4144;\n    vec3 param_17 = _4144;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _4153 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4160;\n    if (!_4153)\n    {\n        _4160 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4160 = _4153;\n    }\n    if (_4160)\n    {\n        vec3 _4169 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4175 = dot(_4169, fa_mesh_fs_params[9].xyz);\n        bool _4179 = fa_mesh_fs_params[9].w > 0.5;\n        float _4180;\n        if (_4179)\n        {\n            _4180 = _4175;\n        }\n        else\n        {\n            _4180 = length(_4169);\n        }\n        float _4192 = _4180 - fa_mesh_fs_params[8].x;\n        if (_4192 > 0.0)\n        {\n            float _4201 = fa_mesh_fs_params[7].w * _4192;\n            float tau = _4201 * _4201;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4217;\n                if (_4179)\n                {\n                    _4217 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4175);\n                }\n                else\n                {\n                    _4217 = fa_mesh_fs_params[0].y;\n                }\n                float _4238 = mix(_4217, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4180, 0.0, 1.0));\n                float _4242 = fa_world_pos.y - _4238;\n                float _4247 = _4238 - fa_mesh_fs_params[8].z;\n                float _4252 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4255 = _4247 <= 0.0;\n                bool _4256 = !_4255;\n                bool _4262;\n                if (_4256)\n                {\n                    _4262 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4262 = _4255;\n                }\n                float _4263;\n                if (_4262)\n                {\n                    _4263 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4263 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4247, 80.0));\n                }\n                bool _4290;\n                if (_4256)\n                {\n                    _4290 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4290 = _4255;\n                }\n                float _4291;\n                if (_4290)\n                {\n                    _4291 = fa_mesh_fs_params[8].y * _4247;\n                }\n                else\n                {\n                    _4291 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4247, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4316 = _4252 <= 0.0;\n                bool _4323;\n                if (!_4316)\n                {\n                    _4323 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4323 = _4316;\n                }\n                float _4324;\n                if (_4323)\n                {\n                    _4324 = fa_mesh_fs_params[8].y * _4252;\n                }\n                else\n                {\n                    _4324 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4252, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4351;\n                if (abs(_4242) < 0.001000000047497451305389404296875)\n                {\n                    _4351 = _4263;\n                }\n                else\n                {\n                    _4351 = (_4324 - _4291) / _4242;\n                }\n                tau += (_4192 * max(_4351, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4474);\n}\n\n",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_386",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
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
            "inst_name": "_2043",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[30];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _785 = base_t;\n    _785.x = _225.x;\n    _785.y = _225.y;\n    _785.z = _225.z;\n    base_t = _785;\n    vec4 _241 = (_785 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _748 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _793 = _279;\n        _793.x = _284.x;\n        _793.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _796 = mrt;\n    _796.x = _313.x;\n    _796.y = _313.y;\n    _796.z = _313.z;\n    mrt = _796;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _753 = fa_mesh_fs_params[20].x;\n    float _754 = fa_mesh_fs_params[20].y;\n    float _757 = fa_mesh_fs_params[20].z;\n    float _756 = fa_mesh_fs_params[21].w;\n    float _759 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _753 *= _355.y;\n            _754 *= _355.z;\n            _756 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _748, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _753, _754, fa_mesh_fs_params[21].xyz, _756, _757, fa_mesh_fs_params[20].w, _759, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _659 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[30];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _785 = base_t;\n    _785.x = _225.x;\n    _785.y = _225.y;\n    _785.z = _225.z;\n    base_t = _785;\n    vec4 _241 = (_785 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _748 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _793 = _279;\n        _793.x = _284.x;\n        _793.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _796 = mrt;\n    _796.x = _313.x;\n    _796.y = _313.y;\n    _796.z = _313.z;\n    mrt = _796;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _753 = fa_mesh_fs_params[20].x;\n    float _754 = fa_mesh_fs_params[20].y;\n    float _757 = fa_mesh_fs_params[20].z;\n    float _756 = fa_mesh_fs_params[21].w;\n    float _759 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _753 *= _355.y;\n            _754 *= _355.z;\n            _756 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _748, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _753, _754, fa_mesh_fs_params[21].xyz, _756, _757, fa_mesh_fs_params[20].w, _759, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _659 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
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
