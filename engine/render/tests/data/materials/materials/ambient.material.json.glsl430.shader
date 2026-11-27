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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1367 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1374;\n    if (!_1367)\n    {\n        _1374 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1374 = _1367;\n    }\n    bool _1382;\n    if (!_1374)\n    {\n        _1382 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1382 = _1374;\n    }\n    bool _1389;\n    if (!_1382)\n    {\n        _1389 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1389 = _1382;\n    }\n    bool _1396;\n    if (!_1389)\n    {\n        _1396 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1396 = _1389;\n    }\n    if (_1396)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1406 = vec4(world_pos, 1.0);\n    float _1412 = dot(fa_mesh_fs_params[16], _1406);\n    if (!(_1412 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1434 = vec2(dot(fa_mesh_fs_params[14], _1406), dot(fa_mesh_fs_params[15], _1406)) / vec2(_1412);\n    int _1438 = int(fa_mesh_fs_params[18].x);\n    int _1442 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1442) + clamp(int(floor(((_1434.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1442 - 1)) * _1438)) + clamp(int(floor(((_1434.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1438 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1518 = fa_cluster_texel(param);\n    return ivec2(int(_1518.x), int(_1518.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _4328 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _4331 = fwidth(_4328);\n    bool _4334 = fa_mesh_fs_params[25].y > 0.5;\n    bool _4341;\n    if (!_4334)\n    {\n        _4341 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _4341 = _4334;\n    }\n    if (_4341)\n    {\n        fa_rt_slope = min(1.5 * _4331, 0.100000001490116119384765625 * _4328);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4357 = fa_cluster_lookup(param);\n    fa_cl_slot = _4357.x;\n    fa_cl_local = _4357.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4567 = fa_linear_to_srgb(param);\n        c = _4567;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4575 = fa_srgb_to_linear(param_1);\n            c = _4575;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _322;\n    if (i.front_facing)\n    {\n        _322 = i.world_normal;\n    }\n    else\n    {\n        _322 = -i.world_normal;\n    }\n    vec3 _346 = normalize(i.world_tangent.xyz - (_322 * dot(_322, i.world_tangent.xyz)));\n    vec3 _373 = normalize(((_346 * m.x) + ((cross(_322, _346) * i.world_tangent.w) * m.y)) + (_322 * m.z));\n    vec3 _376;\n    if (i.front_facing)\n    {\n        _376 = _373;\n    }\n    else\n    {\n        _376 = -_373;\n    }\n    return _376;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4607 = fa_tex_fix(param_2, param_3);\n    vec4 _6515 = base_t;\n    _6515.x = _4607.x;\n    _6515.y = _4607.y;\n    _6515.z = _4607.z;\n    base_t = _6515;\n    vec4 _4621 = (_6515 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6328 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4655 = fa_tex_fix(param_6, param_7);\n        vec3 _4658 = (_4655 * 2.0) - vec3(1.0);\n        vec2 _4663 = _4658.xy * fa_mesh_fs_params[6].x;\n        vec3 _6523 = _4658;\n        _6523.x = _4663.x;\n        _6523.y = _4663.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6523;\n        _6328 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4693 = fa_tex_fix(param_12, param_13);\n    vec4 _6526 = mrt;\n    _6526.x = _4693.x;\n    _6526.y = _4693.y;\n    _6526.z = _4693.z;\n    mrt = _6526;\n    vec4 _4723 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4723.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4734 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4766 = fa_tex_fix(param_20, param_21);\n    float _6333 = fa_mesh_fs_params[20].x;\n    float _6334 = fa_mesh_fs_params[20].y;\n    float _6337 = fa_mesh_fs_params[20].z;\n    float _6336 = fa_mesh_fs_params[21].w;\n    float _6339 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6333 *= _4734.y;\n            _6334 *= _4734.z;\n            _6336 *= _4723.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6337 *= mrt.x;\n            _6339 *= mrt.w;\n        }\n    }\n    return Surface(_4621.xyz, _4621.w, _6328, clamp(fa_mesh_fs_params[5].x * _4693.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4693.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4734.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4766), _6333, _6334, fa_mesh_fs_params[21].xyz, _6336, _6337, fa_mesh_fs_params[20].w, _6339, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1598 = rect.zw - rect.xy;\n    vec2 _1602 = _1598 * atlas;\n    vec2 _1606 = ddx * _1602;\n    vec2 _1610 = ddy * _1602;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1598), clamp(0.5 * log2(max(max(dot(_1606, _1606), dot(_1610, _1610)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1643 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1650;\n    if (!_1643)\n    {\n        _1650 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1650 = _1643;\n    }\n    if (_1650)\n    {\n        return;\n    }\n    vec3 _1656 = dFdx(world_pos);\n    vec3 _1659 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1663 = fa_cluster_texel(param);\n    int _1667 = int(_1663.w);\n    if (_1667 < 1)\n    {\n        return;\n    }\n    int _1677 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1677;\n    vec4 _1681 = fa_light_texel(param_1);\n    vec2 _1684 = _1681.yz;\n    int _1688 = int(_1681.w);\n    int param_2 = _1677 + 1;\n    vec4 _1693 = fa_light_texel(param_2);\n    float _1694 = _1693.x;\n    int _1700 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1704 = int(_1663.z);\n    vec3 _1969;\n    for (int k = 0; k < _1667; k++)\n    {\n        int _1717 = _1704 + k;\n        int param_3 = _1688 + (_1717 >> 2);\n        int _1734 = (_1677 + 2) + (int(fa_light_texel(param_3)[_1717 & 3]) * 7);\n        int param_4 = _1734 + 6;\n        vec4 _1739 = fa_light_texel(param_4);\n        if (((int(_1739.w + 0.5) >> _1700) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1734;\n        vec4 _1754 = fa_light_texel(param_5);\n        int param_6 = _1734 + 1;\n        vec4 _1759 = fa_light_texel(param_6);\n        int param_7 = _1734 + 2;\n        vec4 _1764 = fa_light_texel(param_7);\n        vec3 _1767 = _1754.xyz;\n        float _1772 = dot(_1767, world_pos) + _1754.w;\n        vec3 _1774 = _1759.xyz;\n        float _1779 = dot(_1774, world_pos) + _1759.w;\n        vec3 _1781 = _1764.xyz;\n        float _1786 = dot(_1781, world_pos) + _1764.w;\n        bool _1791 = abs(_1772) > 0.5;\n        bool _1799;\n        if (!_1791)\n        {\n            _1799 = abs(_1779) > 0.5;\n        }\n        else\n        {\n            _1799 = _1791;\n        }\n        bool _1807;\n        if (!_1799)\n        {\n            _1807 = abs(_1786) > 0.5;\n        }\n        else\n        {\n            _1807 = _1799;\n        }\n        if (_1807)\n        {\n            continue;\n        }\n        float _1822 = clamp(dot(geo_normal, normalize(_1781)) * _1739.z, 0.0, 1.0);\n        if (_1822 <= 0.0)\n        {\n            continue;\n        }\n        float _1842 = (clamp((0.5 - abs(_1786)) * 10.0, 0.0, 1.0) * _1822) * _1739.x;\n        vec2 _1850 = vec2(_1772 + 0.5, 0.5 - _1779);\n        vec2 _1860 = vec2(dot(_1767, _1656), dot(_1774, _1656));\n        vec2 _1870 = vec2(dot(_1767, _1659), dot(_1774, _1659));\n        int param_8 = _1734 + 5;\n        vec4 _1875 = fa_light_texel(param_8);\n        int param_9 = _1734 + 3;\n        vec4 _1880 = fa_light_texel(param_9);\n        int param_10 = _1734 + 4;\n        vec4 _1885 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1875.xyz;\n        bool _1895 = _1880.z > _1880.x;\n        if (_1895)\n        {\n            vec4 param_11 = _1880;\n            vec2 param_12 = _1850;\n            vec2 param_13 = _1684;\n            vec2 param_14 = _1860;\n            vec2 param_15 = _1870;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1694 > 0.5) && (_1694 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1921 = fa_dc_to_linear(param_16);\n                vec4 _6416 = tx;\n                _6416.x = _1921.x;\n                _6416.y = _1921.y;\n                _6416.z = _1921.z;\n                tx = _6416;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1842 * tex_a) * _1875.w, 0.0, 1.0)));\n        if (_1885.z > _1885.x)\n        {\n            vec4 param_17 = _1885;\n            vec2 param_18 = _1850;\n            vec2 param_19 = _1684;\n            vec2 param_20 = _1860;\n            vec2 param_21 = _1870;\n            vec4 _1965 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1694 > 1.5)\n            {\n                vec3 param_22 = _1965.xyz;\n                vec3 _1975 = fa_dc_to_srgb(param_22);\n                _1969 = _1975;\n            }\n            else\n            {\n                _1969 = _1965.xyz;\n            }\n            vec3 _1984 = (_1969 * 2.0) - vec3(1.0);\n            vec2 _1989 = _1984.xy * _1739.y;\n            vec3 _2011 = (normalize(_1767) * _1989.x) + (normalize(_1774) * _1989.y);\n            vec3 _2014 = normalize(normal);\n            normal = normalize(mix(_2014, normalize((_2014 * max(_1984.z, 0.0500000007450580596923828125)) + (_2011 - (_2014 * dot(_2014, _2011)))), vec3(clamp(_1842 * (_1895 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3791 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3791;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3900 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3906 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3900 > 0.0005000000237487256526947021484375)\n    {\n        if (_3906)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3900;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3900;\n        }\n    }\n    bool _3958 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3958)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3989 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3989)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3906 || _3958) || _3989)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3811 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3814 = _3811.x;\n    float _3816 = _3811.z;\n    vec2 e = vec2(_3814, _3816);\n    if (_3811.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3816)) * ((_3814 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3814)) * ((_3816 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _4880 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _4885 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _4890 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _4895 = fa_light_texel(param_3);\n    bool _4898 = _4895.z < 0.5;\n    bool _4906;\n    if (!_4898)\n    {\n        _4906 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _4906 = _4898;\n    }\n    if (_4906)\n    {\n        return vec3(0.0);\n    }\n    float _4913 = max(_4880.w, 9.9999997473787516355514526367188e-05);\n    vec3 _4916 = _4885.xyz;\n    vec3 _4920 = _4880.xyz;\n    vec3 _4924 = (fa_world_pos - _4920) / vec3(_4913);\n    vec3 _4933 = min(_4924 + vec3(0.5), (_4916 - vec3(0.5)) - _4924);\n    float _4942 = min(_4933.x, min(_4933.y, _4933.z));\n    if (!(_4942 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4957 = _4916 - vec3(1.0);\n    vec3 _4958 = clamp(_4924, vec3(0.0), _4957);\n    vec3 _4966 = min(floor(_4958), max(_4916 - vec3(2.0), vec3(0.0)));\n    vec3 _4970 = _4958 - _4966;\n    vec3 _4982 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _4913));\n    int _4987 = int(_4890.y + 0.5);\n    float _4992 = 0.3257350027561187744140625 * n.y;\n    float _4996 = 0.3257350027561187744140625 * n.z;\n    float _5000 = 0.3257350027561187744140625 * n.x;\n    float _5007 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _5014 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _5023 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _5030 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _5043 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _5050 = 8 + int(_4895.w);\n    float _5077;\n    float _5090;\n    float _5104;\n    for (int k = 0; k < _5050; k++)\n    {\n        float _5063 = float(k & 1);\n        float _5067 = float((k >> 1) & 1);\n        float _5071 = float((k >> 2) & 1);\n        if (_5063 > 0.5)\n        {\n            _5077 = _4970.x;\n        }\n        else\n        {\n            _5077 = 1.0 - _4970.x;\n        }\n        if (_5067 > 0.5)\n        {\n            _5090 = _4970.y;\n        }\n        else\n        {\n            _5090 = 1.0 - _4970.y;\n        }\n        if (_5071 > 0.5)\n        {\n            _5104 = _4970.z;\n        }\n        else\n        {\n            _5104 = 1.0 - _4970.z;\n        }\n        float _5114 = (_5077 * _5090) * _5104;\n        if (!(_5114 > 0.0))\n        {\n            continue;\n        }\n        vec3 _5127 = min(_4966 + vec3(_5063, _5067, _5071), _4957);\n        int _5147 = int(((_4890.x + _5127.x) + (_4885.x * (_5127.y + (_4885.y * _5127.z)))) + 0.5);\n        vec2 _5162 = vec2(float(_5147 % _4987) * 10.0, 1024.0 + (float(_5147 / _4987) * 11.0));\n        vec2 param_4 = _5162 + vec2(9.5, 10.5);\n        vec4 _5170 = fa_gi_fetch(param_4);\n        bool _5173 = _5170.y < 0.5;\n        bool _5182;\n        if (!_5173)\n        {\n            _5182 = _5170.x > _4895.y;\n        }\n        else\n        {\n            _5182 = _5173;\n        }\n        if (_5182)\n        {\n            continue;\n        }\n        vec3 _5194 = _4982 - (_4920 + (_5127 * _4913));\n        float _5197 = length(_5194);\n        vec3 _5203 = _5194 / vec3(max(_5197, 9.9999997473787516355514526367188e-05));\n        float _5213 = max(9.9999997473787516355514526367188e-05, (dot(-_5203, n) + 1.0) * 0.5);\n        float w = _5114 * (_5213 * _5213);\n        vec3 param_5 = _5203;\n        vec2 param_6 = (_5162 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _5233 = fa_gi_fetch(param_6);\n        float _5240 = _5197 / max(_4890.z, 9.9999997473787516355514526367188e-05);\n        float _5243 = _5233.x;\n        if (_5240 > _5243)\n        {\n            float _5256 = max(_5233.y - (_5243 * _5243), 0.0);\n            float _5261 = _5240 - _5243;\n            float _5270 = _5256 / max(_5256 + (_5261 * _5261), 9.9999999600419720025001879548654e-13);\n            w *= ((_5270 * _5270) * _5270);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _5162 + vec2(0.5, 10.5);\n        vec2 param_8 = _5162 + vec2(1.5, 10.5);\n        vec2 param_9 = _5162 + vec2(2.5, 10.5);\n        vec2 param_10 = _5162 + vec2(3.5, 10.5);\n        vec2 param_11 = _5162 + vec2(4.5, 10.5);\n        vec2 param_12 = _5162 + vec2(5.5, 10.5);\n        vec2 param_13 = _5162 + vec2(6.5, 10.5);\n        vec2 param_14 = _5162 + vec2(7.5, 10.5);\n        vec2 param_15 = _5162 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _4992)) + (fa_gi_fetch(param_9).xyz * _4996)) + (fa_gi_fetch(param_10).xyz * _5000)) + (fa_gi_fetch(param_11).xyz * _5007)) + (fa_gi_fetch(param_12).xyz * _5014)) + (fa_gi_fetch(param_13).xyz * _5023)) + (fa_gi_fetch(param_14).xyz * _5030)) + (fa_gi_fetch(param_15).xyz * _5043)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_4942 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _5398;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _5398 = _4895.x;\n    }\n    else\n    {\n        _5398 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_4890.w * _5398);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _5422 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _5427 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _5432 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _5432) && (k < 8); k++)\n    {\n        int param = _5427 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _5422;\n        vec3 _5457 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5462 = param_3 * left;\n        acc += (_5457 * _5462);\n        left -= _5462;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _5491 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5491;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _5533 = vec4(fa_world_pos, 1.0);\n        vec2 _5552 = vec2(dot(fa_mesh_fs_params[26], _5533), dot(fa_mesh_fs_params[27], _5533)) / vec2(max(dot(fa_mesh_fs_params[28], _5533), 9.9999997473787516355514526367188e-05));\n        float _5561;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5561 = (_5552.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5561 = 0.5 - (_5552.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_5552.x * 0.5) + 0.5, _5561) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4298;\n    if (fa_lm.z > 0.5)\n    {\n        _4298 = 0.0;\n    }\n    else\n    {\n        _4298 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4309 = _4298 < 1.0;\n    bool _4315;\n    if (_4309)\n    {\n        int param = li;\n        _4315 = fa_light_baked(param);\n    }\n    else\n    {\n        _4315 = _4309;\n    }\n    return _4315 ? _4298 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _617 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _630 = (c - (ru * hx)) - p;\n        vec3 _636 = ru * (2.0 * hx);\n        float _642 = max(dot(_636, _636), 9.9999999392252902907785028219223e-09);\n        float _646 = dot(_630, _636);\n        float t = clamp((-_646) / _642, 0.0, 1.0);\n        if (_617)\n        {\n            float _661 = dot(r, _636);\n            float _667 = _642 - (_661 * _661);\n            if (abs(_667) > (9.9999997473787516355514526367188e-06 * _642))\n            {\n                t = clamp(((dot(r, _630) * _661) - _646) / _667, 0.0, 1.0);\n            }\n        }\n        return (p + _630) + (_636 * t);\n    }\n    vec3 q = p;\n    float _699 = dot(r, axis);\n    bool _707;\n    if (_617)\n    {\n        _707 = abs(_699) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _707 = _617;\n    }\n    if (_707)\n    {\n        float _717 = dot(c - p, axis) / _699;\n        if (_717 > 0.0)\n        {\n            q = p + (r * _717);\n        }\n    }\n    vec3 _730 = q - c;\n    vec2 xy = vec2(dot(_730, ru), dot(_730, uu));\n    if (shape > 0.5)\n    {\n        float _745 = length(xy);\n        if (_745 > hx)\n        {\n            xy *= (hx / _745);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _537 = dot(d, right);\n    float _541 = dot(d, up);\n    float _552;\n    if (((_537 * _537) + (_541 * _541)) > 1.0000000133514319600180897396058e-10)\n    {\n        _552 = atan(_541, _537) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _552 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_552 - floor(_552)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _388 = abs(d);\n    float _390 = _388.x;\n    float _392 = _388.y;\n    bool _393 = _390 >= _392;\n    bool _401;\n    if (_393)\n    {\n        _401 = _390 >= _388.z;\n    }\n    else\n    {\n        _401 = _393;\n    }\n    int _402;\n    if (_401)\n    {\n        _402 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _416;\n        if (_392 >= _388.z)\n        {\n            _416 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _416 = (d.z > 0.0) ? 4 : 5;\n        }\n        _402 = _416;\n    }\n    return _402;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _783 = fa_light_base(param);\n    bool _787 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _783;\n    vec4 _791 = fa_light_texel(param_1);\n    int param_2 = _783 + 1;\n    vec4 _796 = fa_light_texel(param_2);\n    float _799 = _796.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _811 = _787 && (_799 > 2.5);\n    fa_light_is_area = _811;\n    bool _813 = _799 < 0.5;\n    vec3 l;\n    if (_813)\n    {\n        l = normalize(_791.xyz);\n        if (_787)\n        {\n            int param_3 = _783 + 6;\n            vec4 _827 = fa_light_texel(param_3);\n            if (_827.z > 0.5)\n            {\n                int param_4 = _783 + 4;\n                vec4 _837 = fa_light_texel(param_4);\n                int param_5 = _783 + 5;\n                vec4 _842 = fa_light_texel(param_5);\n                vec2 param_6 = _827.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _837.xyz) * _837.w, (-dot(world_pos, _842.xyz)) * _842.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _872 = _791.xyz;\n        vec3 _874 = _872 - world_pos;\n        vec3 to_light = _874;\n        float _877 = length(_874);\n        float reach = _877;\n        bool front = true;\n        if (_811)\n        {\n            int param_8 = _783 + 7;\n            reach = max(_877 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _783 + 4;\n            vec4 _901 = fa_light_texel(param_9);\n            int param_10 = _783 + 5;\n            vec4 _906 = fa_light_texel(param_10);\n            int param_11 = _783 + 6;\n            vec4 _911 = fa_light_texel(param_11);\n            float _912 = _911.w;\n            int param_12 = _783 + 2;\n            vec3 _919 = normalize(fa_light_texel(param_12).xyz);\n            bool _921 = _912 > 1.5;\n            bool _929;\n            if (!_921)\n            {\n                _929 = dot(_919, to_light) < 0.0;\n            }\n            else\n            {\n                _929 = _921;\n            }\n            front = _929;\n            vec3 r = vec3(0.0);\n            vec3 _938 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _942 = dot(n, n) > 0.5;\n            bool _950;\n            if (_942)\n            {\n                _950 = dot(_938, _938) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _950 = _942;\n            }\n            if (_950)\n            {\n                r = reflect(-normalize(_938), normalize(n));\n            }\n            vec3 param_13 = _872;\n            vec3 param_14 = _919;\n            vec3 param_15 = _901.xyz;\n            vec3 param_16 = _906.xyz;\n            float param_17 = _901.w;\n            float param_18 = _906.w;\n            float param_19 = _912;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _986 = length(to_light);\n        dist = _986;\n        l = to_light / vec3(max(_986, 9.9999997473787516355514526367188e-05));\n        float _1000 = reach / max(_791.w, 0.001000000047497451305389404296875);\n        float _1006 = clamp(1.0 - (_1000 * _1000), 0.0, 1.0);\n        float _1008;\n        if (front)\n        {\n            _1008 = _1006 * _1006;\n        }\n        else\n        {\n            _1008 = 0.0;\n        }\n        atten = _1008;\n        bool _1019 = _799 < 2.5;\n        if ((_799 > 1.5) && _1019)\n        {\n            int param_22 = _783 + 2;\n            vec4 _1027 = fa_light_texel(param_22);\n            float _1037 = _1027.w;\n            int param_23 = _783 + 3;\n            vec4 _1042 = fa_light_texel(param_23);\n            float _1043 = _1042.x;\n            float cos_inner = _1043;\n            if (_1043 > 1.5)\n            {\n                cos_inner = mix(_1037, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1037, cos_inner, dot(-l, normalize(_1027.xyz)));\n        }\n        if (_787 && (_799 < 1.5))\n        {\n            int param_24 = _783 + 6;\n            vec4 _1067 = fa_light_texel(param_24);\n            if (_1067.z > 0.5)\n            {\n                vec3 _1075 = -to_light;\n                int param_25 = _783 + 4;\n                int param_26 = _783 + 5;\n                vec3 _1089 = fa_light_texel(param_25).xyz;\n                vec3 _1093 = fa_light_texel(param_26).xyz;\n                vec3 _1102 = vec3(dot(_1075, _1089), dot(_1075, _1093), dot(_1075, cross(_1089, _1093)));\n                vec3 param_27 = _1102;\n                int _1106 = fa_cube_face(param_27);\n                int param_28 = _1106;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1133 = vec2(dot(_1102, cross(param_29, param_30)), dot(_1102, param_30)) / vec2(max(dot(_1102, param_29), 9.9999997473787516355514526367188e-05));\n                int _1137 = _1106 / 3;\n                vec2 param_31 = _1067.xy + (vec2(float(_1106 - (_1137 * 3)), float(_1137)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1133.x), 0.5 - (0.5 * _1133.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _783 + 7;\n            vec4 _1167 = fa_light_texel(param_33);\n            if (_1167.z > 0.5)\n            {\n                int param_34 = _783 + 2;\n                int param_35 = _783 + 4;\n                int param_36 = _783 + 5;\n                vec2 param_37 = _1167.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_787 && _1019)\n            {\n                int param_42 = _783 + 6;\n                vec4 _1214 = fa_light_texel(param_42);\n                int param_43 = _783 + 7;\n                vec4 _1219 = fa_light_texel(param_43);\n                bool _1222 = _1214.z > 0.5;\n                bool _1229;\n                if (!_1222)\n                {\n                    _1229 = _1219.z > 0.5;\n                }\n                else\n                {\n                    _1229 = _1222;\n                }\n                if (_1229)\n                {\n                    int param_44 = _783 + 2;\n                    vec4 _1236 = fa_light_texel(param_44);\n                    vec3 _1240 = normalize(_1236.xyz);\n                    int param_45 = _783 + 4;\n                    vec4 _1245 = fa_light_texel(param_45);\n                    int param_46 = _783 + 5;\n                    vec4 _1250 = fa_light_texel(param_46);\n                    if (_1222)\n                    {\n                        vec3 _1258 = -to_light;\n                        float _1265 = _1236.w;\n                        float _1281 = 0.5 / max(dot(_1258, _1240) * (sqrt(max(1.0 - (_1265 * _1265), 0.0)) / max(_1265, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1214.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1258, _1245.xyz) * _1281), 0.5 - (dot(_1258, _1250.xyz) * _1281));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1219.z > 0.5)\n                    {\n                        vec2 param_49 = _1219.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1240;\n                        vec3 param_52 = _1245.xyz;\n                        vec3 param_53 = _1250.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6282 = _796.xyz * atten;\n    if (_787)\n    {\n        _6282 *= fa_light_tint;\n    }\n    int _1349;\n    if (_813)\n    {\n        _1349 = 0;\n    }\n    else\n    {\n        _1349 = ((_799 > 1.5) && (_799 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6282, atten, 1.0, dist, _1349);\n}\n\nfloat fa_rt_local_tap(ivec2 p, ivec2 size, float d, float tol, float div, inout float best)\n{\n    vec4 _3310 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(p, ivec2(0), size - ivec2(1)), 0);\n    bool _3313 = _3310.w > 0.5;\n    bool _3323;\n    if (_3313)\n    {\n        _3323 = abs(d - _3310.x) <= tol;\n    }\n    else\n    {\n        _3323 = _3313;\n    }\n    if (_3323)\n    {\n        best = min(best, mod(floor(_3310.z / div), 256.0) * 0.0039215688593685626983642578125);\n    }\n    return best;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2138 = fa_shadow_depth(param, param_1);\n    float _2142;\n    if (conv.x < 0.5)\n    {\n        _2142 = _2138;\n    }\n    else\n    {\n        _2142 = (conv.y * conv.z) / (conv.z - (_2138 * (conv.z - conv.y)));\n    }\n    return _2142;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2188 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2194 = vec2(cos(_2188), sin(_2188));\n    vec2 dir = _2194;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2203;\n        if (k < 0.0)\n        {\n            _2203 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2203 = k;\n        }\n        float _2222 = clamp((_2203 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2241 = sqrt((float(i) + 0.5) * 0.0625) * _2222;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2241));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2255 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2255 < (zr - (_2241 * plane)))\n            {\n                sum += _2255;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2283 = sum / cnt;\n        float _2293;\n        if (k < 0.0)\n        {\n            _2293 = (-k) / max(_2283, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2293 = k;\n        }\n        radius = clamp(((max(zr - _2283, 0.0) * unit) * _2293) / texel_m, 1.5, 16.0);\n        dir = _2194;\n    }\n    float lit = 0.0;\n    int _2319 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2319; i_1++)\n    {\n        float _2338 = sqrt((float(i_1) + 0.5) / float(_2319)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2338));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2338 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2319);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2543 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2550;\n    if (!_2543)\n    {\n        _2550 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2550 = _2543;\n    }\n    if (_2550)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2563 = fa_light_texel(param);\n    float _2564 = _2563.x;\n    if (_2564 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2573 = int(_2564 + 0.5);\n    int param_1 = _2573;\n    vec4 _2577 = fa_light_texel(param_1);\n    int param_2 = _2573 + 1;\n    vec4 _2582 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2585 = _2577.y;\n    if (_2585 > 0.0)\n    {\n        float _2602 = 1.0 - smoothstep(0.75 * _2585, _2585, length(world - fa_shadows[27].xyz));\n        fade = _2602;\n        if (_2602 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2577.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2626 = (_2573 + 2) + (face * 6);\n    int param_4 = _2626;\n    int param_5 = _2626 + 1;\n    int param_6 = _2626 + 3;\n    vec4 _2640 = fa_light_texel(param_6);\n    int param_7 = _2626 + 4;\n    vec4 _2645 = fa_light_texel(param_7);\n    int param_8 = _2626 + 5;\n    vec4 _2650 = fa_light_texel(param_8);\n    float _2662 = _2650.x * max(dot(_2640, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2667 = clamp(dot(n, l), 0.0, 1.0);\n    float _2690 = clamp(dot(n, _2640.xyz), -1.0, 1.0);\n    float _2709 = min(sqrt(1.0 - (_2690 * _2690)) / max(abs(dot(n, world - lpos)) / max(dot(_2640, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2712 = _2582.y;\n    float _2714;\n    if (_2712 > 0.0)\n    {\n        _2714 = _2712;\n    }\n    else\n    {\n        _2714 = 1.5 * _2662;\n    }\n    vec4 _2734 = vec4(world + (n * (_2714 * sqrt(1.0 - (_2667 * _2667)))), 1.0);\n    float _2738 = dot(_2640, _2734);\n    float _2741 = _2650.y;\n    if (_2738 < _2741)\n    {\n        return 1.0;\n    }\n    vec2 _2756 = vec2(dot(fa_light_texel(param_4), _2734), dot(fa_light_texel(param_5), _2734)) / vec2(_2738);\n    float _2758 = _2756.x;\n    bool _2761 = _2758 < _2645.x;\n    bool _2770;\n    if (!_2761)\n    {\n        _2770 = _2758 > _2645.z;\n    }\n    else\n    {\n        _2770 = _2761;\n    }\n    bool _2779;\n    if (!_2770)\n    {\n        _2779 = _2756.y < _2645.y;\n    }\n    else\n    {\n        _2779 = _2770;\n    }\n    bool _2788;\n    if (!_2779)\n    {\n        _2788 = _2756.y > _2645.w;\n    }\n    else\n    {\n        _2788 = _2779;\n    }\n    if (_2788)\n    {\n        return 1.0;\n    }\n    float _2794 = _2582.x;\n    float _2796;\n    if (_2794 > 0.0)\n    {\n        _2796 = _2794;\n    }\n    else\n    {\n        _2796 = 1.5 * _2662;\n    }\n    vec2 param_9 = _2756;\n    vec4 param_10 = _2645;\n    float param_11 = _2738 - (_2796 * (1.0 + (0.5 * _2709)));\n    float param_12 = _2662;\n    float param_13 = 1.0;\n    float param_14 = _2650.z * 0.25;\n    float param_15 = (_2662 * min(_2709, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2741, _2650.z);\n    int param_17 = int(_2577.z + 0.5);\n    float param_18 = _2577.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3341 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3347;\n    if (_3341)\n    {\n        _3347 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3347 = _3341;\n    }\n    bool _3353;\n    if (_3347)\n    {\n        _3353 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3353 = _3347;\n    }\n    if (_3353)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3365 = fa_light_texel(param);\n        float _3366 = _3365.z;\n        if (_3366 > 0.5)\n        {\n            float _3379 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3385 = ((0.00200000009499490261077880859375 * _3379) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3391 = vec4(world, 1.0);\n            float _3396 = dot(fa_mesh_fs_params[28], _3391);\n            if (_3396 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3413 = vec2(dot(fa_mesh_fs_params[26], _3391), dot(fa_mesh_fs_params[27], _3391)) / vec2(_3396);\n                float _3418 = (_3413.x * 0.5) + 0.5;\n                float _3422;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3422 = (_3413.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3422 = 0.5 - (_3413.y * 0.5);\n                }\n                bool _3438 = _3418 >= 0.0;\n                bool _3444;\n                if (_3438)\n                {\n                    _3444 = _3418 < 1.0;\n                }\n                else\n                {\n                    _3444 = _3438;\n                }\n                bool _3450;\n                if (_3444)\n                {\n                    _3450 = _3422 >= 0.0;\n                }\n                else\n                {\n                    _3450 = _3444;\n                }\n                bool _3456;\n                if (_3450)\n                {\n                    _3456 = _3422 < 1.0;\n                }\n                else\n                {\n                    _3456 = _3450;\n                }\n                if (_3456)\n                {\n                    ivec2 _3463 = ivec2(fa_mesh_fs_params[24].zw);\n                    ivec2 _3474 = clamp(ivec2(vec2(_3418, _3422) * fa_mesh_fs_params[24].zw), ivec2(0), _3463 - ivec2(1));\n                    float _3478;\n                    if (_3366 < 1.5)\n                    {\n                        _3478 = 1.0;\n                    }\n                    else\n                    {\n                        _3478 = (_3366 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    vec4 _3494 = texelFetch(fa_screen_tex_fa_shadow_smp, _3474, 0);\n                    bool _3497 = _3494.w > 0.5;\n                    bool _3507;\n                    if (_3497)\n                    {\n                        _3507 = abs(_3379 - _3494.x) <= _3385;\n                    }\n                    else\n                    {\n                        _3507 = _3497;\n                    }\n                    if (_3507)\n                    {\n                        best = mod(floor(_3494.z / _3478), 256.0) * 0.0039215688593685626983642578125;\n                    }\n                    else\n                    {\n                        ivec2 param_1 = _3474 + ivec2(-1);\n                        ivec2 param_2 = _3463;\n                        float param_3 = _3379;\n                        float param_4 = _3385;\n                        float param_5 = _3478;\n                        float param_6 = best;\n                        float _3533 = fa_rt_local_tap(param_1, param_2, param_3, param_4, param_5, param_6);\n                        best = _3533;\n                        ivec2 param_7 = _3474 + ivec2(0, -1);\n                        ivec2 param_8 = _3463;\n                        float param_9 = _3379;\n                        float param_10 = _3385;\n                        float param_11 = _3478;\n                        float param_12 = _3533;\n                        float _3548 = fa_rt_local_tap(param_7, param_8, param_9, param_10, param_11, param_12);\n                        best = _3548;\n                        ivec2 param_13 = _3474 + ivec2(1, -1);\n                        ivec2 param_14 = _3463;\n                        float param_15 = _3379;\n                        float param_16 = _3385;\n                        float param_17 = _3478;\n                        float param_18 = _3548;\n                        float _3563 = fa_rt_local_tap(param_13, param_14, param_15, param_16, param_17, param_18);\n                        best = _3563;\n                        ivec2 param_19 = _3474 + ivec2(-1, 0);\n                        ivec2 param_20 = _3463;\n                        float param_21 = _3379;\n                        float param_22 = _3385;\n                        float param_23 = _3478;\n                        float param_24 = _3563;\n                        float _3578 = fa_rt_local_tap(param_19, param_20, param_21, param_22, param_23, param_24);\n                        best = _3578;\n                        ivec2 param_25 = _3474 + ivec2(1, 0);\n                        ivec2 param_26 = _3463;\n                        float param_27 = _3379;\n                        float param_28 = _3385;\n                        float param_29 = _3478;\n                        float param_30 = _3578;\n                        float _3593 = fa_rt_local_tap(param_25, param_26, param_27, param_28, param_29, param_30);\n                        best = _3593;\n                        ivec2 param_31 = _3474 + ivec2(-1, 1);\n                        ivec2 param_32 = _3463;\n                        float param_33 = _3379;\n                        float param_34 = _3385;\n                        float param_35 = _3478;\n                        float param_36 = _3593;\n                        float _3608 = fa_rt_local_tap(param_31, param_32, param_33, param_34, param_35, param_36);\n                        best = _3608;\n                        ivec2 param_37 = _3474 + ivec2(0, 1);\n                        ivec2 param_38 = _3463;\n                        float param_39 = _3379;\n                        float param_40 = _3385;\n                        float param_41 = _3478;\n                        float param_42 = _3608;\n                        float _3623 = fa_rt_local_tap(param_37, param_38, param_39, param_40, param_41, param_42);\n                        best = _3623;\n                        ivec2 param_43 = _3474 + ivec2(1);\n                        ivec2 param_44 = _3463;\n                        float param_45 = _3379;\n                        float param_46 = _3385;\n                        float param_47 = _3478;\n                        float param_48 = _3623;\n                        float _3638 = fa_rt_local_tap(param_43, param_44, param_45, param_46, param_47, param_48);\n                        best = _3638;\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3646;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_49 = li;\n                            vec3 param_50 = lpos;\n                            vec3 param_51 = world;\n                            vec3 param_52 = n;\n                            vec3 param_53 = l;\n                            _3646 = min(best, fa_shadow_local(param_49, param_50, param_51, param_52, param_53));\n                        }\n                        else\n                        {\n                            _3646 = best;\n                        }\n                        return _3646;\n                    }\n                }\n            }\n            float _3669;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_54 = li;\n                vec3 param_55 = lpos;\n                vec3 param_56 = world;\n                vec3 param_57 = n;\n                vec3 param_58 = l;\n                _3669 = fa_shadow_local(param_54, param_55, param_56, param_57, param_58);\n            }\n            else\n            {\n                _3669 = 1.0;\n            }\n            return _3669;\n        }\n    }\n    int param_59 = li;\n    vec3 param_60 = lpos;\n    vec3 param_61 = world;\n    vec3 param_62 = n;\n    vec3 param_63 = l;\n    return fa_shadow_local(param_59, param_60, param_61, param_62, param_63);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2081;\n    if (i == 0)\n    {\n        _2081 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2097;\n        if (i == 1)\n        {\n            _2097 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2105;\n            if (i == 2)\n            {\n                _2105 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2105 = fa_shadows[24].w;\n            }\n            _2097 = _2105;\n        }\n        _2081 = _2097;\n    }\n    return _2081;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2384 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2389 = clamp(dot(n, l), 0.0, 1.0);\n    float _2395 = sqrt(1.0 - (_2389 * _2389));\n    float _2403 = min(_2395 / max(_2389, 0.20000000298023223876953125), 4.0);\n    float _2408;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2408 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2408 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2433 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2408 * _2395)), 1.0);\n    float _2440 = _2433.x;\n    bool _2443 = _2440 < fa_shadows[ci * 1 + 16].x;\n    bool _2452;\n    if (!_2443)\n    {\n        _2452 = _2440 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2452 = _2443;\n    }\n    bool _2461;\n    if (!_2452)\n    {\n        _2461 = _2433.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2461 = _2452;\n    }\n    bool _2470;\n    if (!_2461)\n    {\n        _2470 = _2433.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2470 = _2461;\n    }\n    bool _2477;\n    if (!_2470)\n    {\n        _2477 = _2433.z > 1.0;\n    }\n    else\n    {\n        _2477 = _2470;\n    }\n    if (_2477)\n    {\n        return -1.0;\n    }\n    float _2485;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2485 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2485 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2433.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2433.z - ((_2485 * (1.0 + (0.5 * _2403))) / _2384);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2384;\n    float param_5 = _2384 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2403, 3.0)) * 0.5) / _2384;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2863 = int(fa_shadows[25].x + 0.5);\n    if (_2863 < 1)\n    {\n        return 1.0;\n    }\n    float _2878 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2863 - 1;\n    if (_2878 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2890 = _2863 > 1;\n    bool _2897;\n    if (_2890)\n    {\n        _2897 = _2878 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2897 = _2890;\n    }\n    if (_2897)\n    {\n        ci = 1;\n    }\n    bool _2901 = _2863 > 2;\n    bool _2908;\n    if (_2901)\n    {\n        _2908 = _2878 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2908 = _2901;\n    }\n    if (_2908)\n    {\n        ci = 2;\n    }\n    bool _2912 = _2863 > 3;\n    bool _2919;\n    if (_2912)\n    {\n        _2919 = _2878 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2919 = _2912;\n    }\n    if (_2919)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2930 = min(_2863, 4);\n    float _2971;\n    for (int c = ci; c < _2930; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2950 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2950;\n            break;\n        }\n        if (_2950 < 0.0)\n        {\n            continue;\n        }\n        s = _2950;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2971 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2971 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _2990 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2971, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2878 - (fa_shadow_split_at(param_7) - _2990)) / _2990, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3022;\n        if ((ci + 1) < _2863)\n        {\n            _3022 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3022 = 1.0;\n        }\n        s = mix(s, _3022, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3127 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3133;\n    if (_3127)\n    {\n        _3133 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3133 = _3127;\n    }\n    if (_3133)\n    {\n        float _3147 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3155 = vec4(fa_world_pos, 1.0);\n        float _3161 = dot(fa_mesh_fs_params[28], _3155);\n        if (_3161 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3180 = vec2(dot(fa_mesh_fs_params[26], _3155), dot(fa_mesh_fs_params[27], _3155)) / vec2(_3161);\n            float _3185 = (_3180.x * 0.5) + 0.5;\n            float _3189;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3189 = (_3180.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3189 = 0.5 - (_3180.y * 0.5);\n            }\n            bool _3205 = _3185 >= 0.0;\n            bool _3211;\n            if (_3205)\n            {\n                _3211 = _3185 < 1.0;\n            }\n            else\n            {\n                _3211 = _3205;\n            }\n            bool _3217;\n            if (_3211)\n            {\n                _3217 = _3189 >= 0.0;\n            }\n            else\n            {\n                _3217 = _3211;\n            }\n            bool _3223;\n            if (_3217)\n            {\n                _3223 = _3189 < 1.0;\n            }\n            else\n            {\n                _3223 = _3217;\n            }\n            if (_3223)\n            {\n                vec4 _3248 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3185, _3189) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3251 = _3248.w > 0.5;\n                bool _3267;\n                if (_3251)\n                {\n                    _3267 = abs(_3147 - _3248.x) <= (((0.00200000009499490261077880859375 * _3147) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3267 = _3251;\n                }\n                if (_3267)\n                {\n                    float _3273;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3273 = min(_3248.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3273 = _3248.y;\n                    }\n                    return _3273;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4040 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4047;\n    if (!_4040)\n    {\n        _4047 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4047 = _4040;\n    }\n    if (_4047)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4060 = fa_light_texel(param);\n    float _4061 = _4060.y;\n    float len = _4061;\n    if (_4061 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4073 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4082 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4073);\n    if (_4082 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4088 = len;\n    float _4091 = min(_4088, 0.89999997615814208984375 * dist);\n    len = _4091;\n    float _4097 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4073);\n    float _4102 = _4097 + (0.5 * _4091);\n    vec3 _4108 = world + (gn * _4097);\n    float _4110 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4172;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4126 = (float(k) + _4110) * 0.083333335816860198974609375;\n        vec3 _4134 = _4108 + (l * (_4126 * len));\n        vec4 _4140 = vec4(_4134, 1.0);\n        float _4145 = dot(fa_mesh_fs_params[28], _4140);\n        if (_4145 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4163 = vec2(dot(fa_mesh_fs_params[26], _4140), dot(fa_mesh_fs_params[27], _4140)) / vec2(_4145);\n        float _4167 = _4163.x * 0.5;\n        float _4168 = _4167 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4172 = (_4163.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4172 = 0.5 - (_4163.y * 0.5);\n        }\n        bool _4188 = _4168 < 0.0;\n        bool _4195;\n        if (!_4188)\n        {\n            _4195 = _4168 >= 1.0;\n        }\n        else\n        {\n            _4195 = _4188;\n        }\n        bool _4202;\n        if (!_4195)\n        {\n            _4202 = _4172 < 0.0;\n        }\n        else\n        {\n            _4202 = _4195;\n        }\n        bool _4209;\n        if (!_4202)\n        {\n            _4209 = _4172 >= 1.0;\n        }\n        else\n        {\n            _4209 = _4202;\n        }\n        if (_4209)\n        {\n            break;\n        }\n        vec4 _4233 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4168, _4172) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4233.w < 0.5)\n        {\n            continue;\n        }\n        float _4251 = (dot(fa_mesh_fs_params[29].xyz, _4134) + fa_mesh_fs_params[29].w) - _4233.x;\n        if ((_4251 > _4097) && (_4251 < _4102))\n        {\n            occ = max(occ, (1.0 - (_4126 * _4126)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4168, 0.5 - _4167), min(_4172, 1.0 - _4172))));\n        }\n    }\n    return 1.0 - (occ * _4082);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4383 = fa_baked_keep(param);\n    if (_4383 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4409 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6308 = _4409.color;\n    float _6309 = _4409.attenuation;\n    float _6310 = _4409.shadow;\n    bool _4412 = _4409.type == 0;\n    if (_4412 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4409.direction;\n        float _4423 = fa_shadow_factor(param_5, param_6);\n        _6310 = _4423;\n        _6308 *= _4423;\n    }\n    else\n    {\n        bool _4434 = _4409.type != 0;\n        bool _4440;\n        if (_4434)\n        {\n            _4440 = _6309 > 0.0;\n        }\n        else\n        {\n            _4440 = _4434;\n        }\n        if (_4440)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4409.direction;\n            float _4459 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6310 = _4459;\n            _6308 *= _4459;\n        }\n    }\n    bool _4469 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4475;\n    if (_4469)\n    {\n        _4475 = _6309 > 0.0;\n    }\n    else\n    {\n        _4475 = _4469;\n    }\n    if (_4475)\n    {\n        float _4482;\n        if (_4412)\n        {\n            _4482 = 1000000000.0;\n        }\n        else\n        {\n            _4482 = _4409._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4409.direction;\n        float param_18 = _4482;\n        float _4500 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6310 *= _4500;\n        _6308 *= _4500;\n    }\n    float _4513 = _6309;\n    float _4514 = _4513 * _4383;\n    _6309 = _4514;\n    vec3 _4518 = _6308;\n    vec3 _4519 = _4518 * _4383;\n    _6308 = _4519;\n    return LightSample(_4409.direction, _4519, _4514, _6310, _4409._distance, _4409.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3050 = int(fa_shadows[25].x + 0.5);\n    float _3060 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3065 = _3050 > 0;\n    bool _3074;\n    if (_3065)\n    {\n        int param = _3050 - 1;\n        _3074 = _3060 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3074 = _3065;\n    }\n    if (_3074)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3080 = _3050 > 1;\n        bool _3087;\n        if (_3080)\n        {\n            _3087 = _3060 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3087 = _3080;\n        }\n        if (_3087)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3093 = _3050 > 2;\n        bool _3100;\n        if (_3093)\n        {\n            _3100 = _3060 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3100 = _3093;\n        }\n        if (_3100)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3106 = _3050 > 3;\n        bool _3113;\n        if (_3106)\n        {\n            _3113 = _3060 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3113 = _3106;\n        }\n        if (_3113)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _6100 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6100 = -_6100;\n    }\n    vec3 _5674 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6100, fa_world_tangent, fa_uv, fa_vertex_color, _5674, gl_FrontFacing);\n    Surface _5682 = fa_standard_surface(param_1);\n    vec3 _6139 = _5682.albedo;\n    float _6140 = _5682.alpha;\n    vec3 _6141 = _5682.normal;\n    float _6142 = _5682.metallic;\n    float _6143 = _5682.roughness;\n    float _6144 = _5682.occlusion;\n    vec3 _6145 = _5682.emission;\n    float _6146 = _5682.clearcoat;\n    float _6147 = _5682.clearcoat_roughness;\n    vec3 _6148 = _5682.sheen_color;\n    float _6149 = _5682.sheen_roughness;\n    float _6150 = _5682.anisotropy;\n    float _6151 = _5682.anisotropy_rotation;\n    float _6152 = _5682.specular;\n    float _6153 = _5682.ior;\n    vec3 _6154 = _5682.specular_color;\n    float _6155 = _5682.transmission;\n    float _6156 = _5682.thickness;\n    vec3 _6157 = _5682.attenuation_color;\n    float _6158 = _5682.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6100, fa_world_tangent, fa_uv, fa_vertex_color, _5674, gl_FrontFacing);\n    Surface param_3 = _5682;\n    surface(param_2, param_3);\n    _6139 = param_3.albedo;\n    _6140 = param_3.alpha;\n    _6141 = param_3.normal;\n    _6142 = param_3.metallic;\n    _6143 = param_3.roughness;\n    _6144 = param_3.occlusion;\n    _6145 = param_3.emission;\n    _6146 = param_3.clearcoat;\n    _6147 = param_3.clearcoat_roughness;\n    _6148 = param_3.sheen_color;\n    _6149 = param_3.sheen_roughness;\n    _6150 = param_3.anisotropy;\n    _6151 = param_3.anisotropy_rotation;\n    _6152 = param_3.specular;\n    _6153 = param_3.ior;\n    _6154 = param_3.specular_color;\n    _6155 = param_3.transmission;\n    _6156 = param_3.thickness;\n    _6157 = param_3.attenuation_color;\n    _6158 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6100;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6139 = param_6;\n    _6141 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6139;\n    }\n    else\n    {\n        vec3 _5721 = _6141;\n        vec3 _5722 = normalize(_5721);\n        _6141 = _5722;\n        vec3 param_8 = _5722;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _6100, fa_world_tangent, fa_uv, fa_vertex_color, _5674, gl_FrontFacing);\n        Surface param_10 = Surface(_6139, _6140, _6141, _6142, _6143, _6144, _6145, _6146, _6147, _6148, _6149, _6150, _6151, _6152, _6153, _6154, _6155, _6156, _6157, _6158);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _5741 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5741; ln++)\n        {\n            int param_12 = ln;\n            int _5754 = fa_cl_light(param_12);\n            int param_13 = _5754;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _5754;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _6100;\n            LightSample _5770 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _6100, fa_world_tangent, fa_uv, fa_vertex_color, _5674, gl_FrontFacing);\n            Surface param_18 = Surface(_6139, _6140, _6141, _6142, _6143, _6144, _6145, _6146, _6147, _6148, _6149, _6150, _6151, _6152, _6153, _6154, _6155, _6156, _6157, _6158);\n            LightSample param_19 = _5770;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _5785 = result;\n    vec3 _5786 = _5785 + _6145;\n    result = _5786;\n    vec3 param_20 = _5786;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5795 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5802;\n    if (!_5795)\n    {\n        _5802 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5802 = _5795;\n    }\n    if (_5802)\n    {\n        vec3 _5811 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5817 = dot(_5811, fa_mesh_fs_params[9].xyz);\n        bool _5821 = fa_mesh_fs_params[9].w > 0.5;\n        float _5822;\n        if (_5821)\n        {\n            _5822 = _5817;\n        }\n        else\n        {\n            _5822 = length(_5811);\n        }\n        float _5834 = _5822 - fa_mesh_fs_params[8].x;\n        if (_5834 > 0.0)\n        {\n            float _5843 = fa_mesh_fs_params[7].w * _5834;\n            float tau = _5843 * _5843;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5859;\n                if (_5821)\n                {\n                    _5859 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5817);\n                }\n                else\n                {\n                    _5859 = fa_mesh_fs_params[0].y;\n                }\n                float _5880 = mix(_5859, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5822, 0.0, 1.0));\n                float _5884 = fa_world_pos.y - _5880;\n                float _5889 = _5880 - fa_mesh_fs_params[8].z;\n                float _5894 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5897 = _5889 <= 0.0;\n                bool _5898 = !_5897;\n                bool _5904;\n                if (_5898)\n                {\n                    _5904 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5904 = _5897;\n                }\n                float _5905;\n                if (_5904)\n                {\n                    _5905 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5905 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5889, 80.0));\n                }\n                bool _5932;\n                if (_5898)\n                {\n                    _5932 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5932 = _5897;\n                }\n                float _5933;\n                if (_5932)\n                {\n                    _5933 = fa_mesh_fs_params[8].y * _5889;\n                }\n                else\n                {\n                    _5933 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5889, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5958 = _5894 <= 0.0;\n                bool _5965;\n                if (!_5958)\n                {\n                    _5965 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5965 = _5958;\n                }\n                float _5966;\n                if (_5965)\n                {\n                    _5966 = fa_mesh_fs_params[8].y * _5894;\n                }\n                else\n                {\n                    _5966 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5894, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5993;\n                if (abs(_5884) < 0.001000000047497451305389404296875)\n                {\n                    _5993 = _5905;\n                }\n                else\n                {\n                    _5993 = (_5966 - _5933) / _5884;\n                }\n                tau += (_5834 * max(_5993, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6140);\n}\n\n",
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
            "inst_name": "_439",
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
            "inst_name": "_2091",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1367 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1374;\n    if (!_1367)\n    {\n        _1374 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1374 = _1367;\n    }\n    bool _1382;\n    if (!_1374)\n    {\n        _1382 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1382 = _1374;\n    }\n    bool _1389;\n    if (!_1382)\n    {\n        _1389 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1389 = _1382;\n    }\n    bool _1396;\n    if (!_1389)\n    {\n        _1396 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1396 = _1389;\n    }\n    if (_1396)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1406 = vec4(world_pos, 1.0);\n    float _1412 = dot(fa_mesh_fs_params[16], _1406);\n    if (!(_1412 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1434 = vec2(dot(fa_mesh_fs_params[14], _1406), dot(fa_mesh_fs_params[15], _1406)) / vec2(_1412);\n    int _1438 = int(fa_mesh_fs_params[18].x);\n    int _1442 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1442) + clamp(int(floor(((_1434.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1442 - 1)) * _1438)) + clamp(int(floor(((_1434.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1438 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1518 = fa_cluster_texel(param);\n    return ivec2(int(_1518.x), int(_1518.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _4328 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _4331 = fwidth(_4328);\n    bool _4334 = fa_mesh_fs_params[25].y > 0.5;\n    bool _4341;\n    if (!_4334)\n    {\n        _4341 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _4341 = _4334;\n    }\n    if (_4341)\n    {\n        fa_rt_slope = min(1.5 * _4331, 0.100000001490116119384765625 * _4328);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4357 = fa_cluster_lookup(param);\n    fa_cl_slot = _4357.x;\n    fa_cl_local = _4357.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4567 = fa_linear_to_srgb(param);\n        c = _4567;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4575 = fa_srgb_to_linear(param_1);\n            c = _4575;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _322;\n    if (i.front_facing)\n    {\n        _322 = i.world_normal;\n    }\n    else\n    {\n        _322 = -i.world_normal;\n    }\n    vec3 _346 = normalize(i.world_tangent.xyz - (_322 * dot(_322, i.world_tangent.xyz)));\n    vec3 _373 = normalize(((_346 * m.x) + ((cross(_322, _346) * i.world_tangent.w) * m.y)) + (_322 * m.z));\n    vec3 _376;\n    if (i.front_facing)\n    {\n        _376 = _373;\n    }\n    else\n    {\n        _376 = -_373;\n    }\n    return _376;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4607 = fa_tex_fix(param_2, param_3);\n    vec4 _6515 = base_t;\n    _6515.x = _4607.x;\n    _6515.y = _4607.y;\n    _6515.z = _4607.z;\n    base_t = _6515;\n    vec4 _4621 = (_6515 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6328 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4655 = fa_tex_fix(param_6, param_7);\n        vec3 _4658 = (_4655 * 2.0) - vec3(1.0);\n        vec2 _4663 = _4658.xy * fa_mesh_fs_params[6].x;\n        vec3 _6523 = _4658;\n        _6523.x = _4663.x;\n        _6523.y = _4663.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6523;\n        _6328 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4693 = fa_tex_fix(param_12, param_13);\n    vec4 _6526 = mrt;\n    _6526.x = _4693.x;\n    _6526.y = _4693.y;\n    _6526.z = _4693.z;\n    mrt = _6526;\n    vec4 _4723 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4723.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4734 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4766 = fa_tex_fix(param_20, param_21);\n    float _6333 = fa_mesh_fs_params[20].x;\n    float _6334 = fa_mesh_fs_params[20].y;\n    float _6337 = fa_mesh_fs_params[20].z;\n    float _6336 = fa_mesh_fs_params[21].w;\n    float _6339 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6333 *= _4734.y;\n            _6334 *= _4734.z;\n            _6336 *= _4723.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6337 *= mrt.x;\n            _6339 *= mrt.w;\n        }\n    }\n    return Surface(_4621.xyz, _4621.w, _6328, clamp(fa_mesh_fs_params[5].x * _4693.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4693.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4734.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4766), _6333, _6334, fa_mesh_fs_params[21].xyz, _6336, _6337, fa_mesh_fs_params[20].w, _6339, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1598 = rect.zw - rect.xy;\n    vec2 _1602 = _1598 * atlas;\n    vec2 _1606 = ddx * _1602;\n    vec2 _1610 = ddy * _1602;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1598), clamp(0.5 * log2(max(max(dot(_1606, _1606), dot(_1610, _1610)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1643 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1650;\n    if (!_1643)\n    {\n        _1650 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1650 = _1643;\n    }\n    if (_1650)\n    {\n        return;\n    }\n    vec3 _1656 = dFdx(world_pos);\n    vec3 _1659 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1663 = fa_cluster_texel(param);\n    int _1667 = int(_1663.w);\n    if (_1667 < 1)\n    {\n        return;\n    }\n    int _1677 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1677;\n    vec4 _1681 = fa_light_texel(param_1);\n    vec2 _1684 = _1681.yz;\n    int _1688 = int(_1681.w);\n    int param_2 = _1677 + 1;\n    vec4 _1693 = fa_light_texel(param_2);\n    float _1694 = _1693.x;\n    int _1700 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1704 = int(_1663.z);\n    vec3 _1969;\n    for (int k = 0; k < _1667; k++)\n    {\n        int _1717 = _1704 + k;\n        int param_3 = _1688 + (_1717 >> 2);\n        int _1734 = (_1677 + 2) + (int(fa_light_texel(param_3)[_1717 & 3]) * 7);\n        int param_4 = _1734 + 6;\n        vec4 _1739 = fa_light_texel(param_4);\n        if (((int(_1739.w + 0.5) >> _1700) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1734;\n        vec4 _1754 = fa_light_texel(param_5);\n        int param_6 = _1734 + 1;\n        vec4 _1759 = fa_light_texel(param_6);\n        int param_7 = _1734 + 2;\n        vec4 _1764 = fa_light_texel(param_7);\n        vec3 _1767 = _1754.xyz;\n        float _1772 = dot(_1767, world_pos) + _1754.w;\n        vec3 _1774 = _1759.xyz;\n        float _1779 = dot(_1774, world_pos) + _1759.w;\n        vec3 _1781 = _1764.xyz;\n        float _1786 = dot(_1781, world_pos) + _1764.w;\n        bool _1791 = abs(_1772) > 0.5;\n        bool _1799;\n        if (!_1791)\n        {\n            _1799 = abs(_1779) > 0.5;\n        }\n        else\n        {\n            _1799 = _1791;\n        }\n        bool _1807;\n        if (!_1799)\n        {\n            _1807 = abs(_1786) > 0.5;\n        }\n        else\n        {\n            _1807 = _1799;\n        }\n        if (_1807)\n        {\n            continue;\n        }\n        float _1822 = clamp(dot(geo_normal, normalize(_1781)) * _1739.z, 0.0, 1.0);\n        if (_1822 <= 0.0)\n        {\n            continue;\n        }\n        float _1842 = (clamp((0.5 - abs(_1786)) * 10.0, 0.0, 1.0) * _1822) * _1739.x;\n        vec2 _1850 = vec2(_1772 + 0.5, 0.5 - _1779);\n        vec2 _1860 = vec2(dot(_1767, _1656), dot(_1774, _1656));\n        vec2 _1870 = vec2(dot(_1767, _1659), dot(_1774, _1659));\n        int param_8 = _1734 + 5;\n        vec4 _1875 = fa_light_texel(param_8);\n        int param_9 = _1734 + 3;\n        vec4 _1880 = fa_light_texel(param_9);\n        int param_10 = _1734 + 4;\n        vec4 _1885 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1875.xyz;\n        bool _1895 = _1880.z > _1880.x;\n        if (_1895)\n        {\n            vec4 param_11 = _1880;\n            vec2 param_12 = _1850;\n            vec2 param_13 = _1684;\n            vec2 param_14 = _1860;\n            vec2 param_15 = _1870;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1694 > 0.5) && (_1694 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1921 = fa_dc_to_linear(param_16);\n                vec4 _6416 = tx;\n                _6416.x = _1921.x;\n                _6416.y = _1921.y;\n                _6416.z = _1921.z;\n                tx = _6416;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1842 * tex_a) * _1875.w, 0.0, 1.0)));\n        if (_1885.z > _1885.x)\n        {\n            vec4 param_17 = _1885;\n            vec2 param_18 = _1850;\n            vec2 param_19 = _1684;\n            vec2 param_20 = _1860;\n            vec2 param_21 = _1870;\n            vec4 _1965 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1694 > 1.5)\n            {\n                vec3 param_22 = _1965.xyz;\n                vec3 _1975 = fa_dc_to_srgb(param_22);\n                _1969 = _1975;\n            }\n            else\n            {\n                _1969 = _1965.xyz;\n            }\n            vec3 _1984 = (_1969 * 2.0) - vec3(1.0);\n            vec2 _1989 = _1984.xy * _1739.y;\n            vec3 _2011 = (normalize(_1767) * _1989.x) + (normalize(_1774) * _1989.y);\n            vec3 _2014 = normalize(normal);\n            normal = normalize(mix(_2014, normalize((_2014 * max(_1984.z, 0.0500000007450580596923828125)) + (_2011 - (_2014 * dot(_2014, _2011)))), vec3(clamp(_1842 * (_1895 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3791 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3791;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3900 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3906 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3900 > 0.0005000000237487256526947021484375)\n    {\n        if (_3906)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3900;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3900;\n        }\n    }\n    bool _3958 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3958)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3989 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3989)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3906 || _3958) || _3989)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3811 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3814 = _3811.x;\n    float _3816 = _3811.z;\n    vec2 e = vec2(_3814, _3816);\n    if (_3811.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3816)) * ((_3814 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3814)) * ((_3816 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _4880 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _4885 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _4890 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _4895 = fa_light_texel(param_3);\n    bool _4898 = _4895.z < 0.5;\n    bool _4906;\n    if (!_4898)\n    {\n        _4906 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _4906 = _4898;\n    }\n    if (_4906)\n    {\n        return vec3(0.0);\n    }\n    float _4913 = max(_4880.w, 9.9999997473787516355514526367188e-05);\n    vec3 _4916 = _4885.xyz;\n    vec3 _4920 = _4880.xyz;\n    vec3 _4924 = (fa_world_pos - _4920) / vec3(_4913);\n    vec3 _4933 = min(_4924 + vec3(0.5), (_4916 - vec3(0.5)) - _4924);\n    float _4942 = min(_4933.x, min(_4933.y, _4933.z));\n    if (!(_4942 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4957 = _4916 - vec3(1.0);\n    vec3 _4958 = clamp(_4924, vec3(0.0), _4957);\n    vec3 _4966 = min(floor(_4958), max(_4916 - vec3(2.0), vec3(0.0)));\n    vec3 _4970 = _4958 - _4966;\n    vec3 _4982 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _4913));\n    int _4987 = int(_4890.y + 0.5);\n    float _4992 = 0.3257350027561187744140625 * n.y;\n    float _4996 = 0.3257350027561187744140625 * n.z;\n    float _5000 = 0.3257350027561187744140625 * n.x;\n    float _5007 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _5014 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _5023 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _5030 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _5043 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _5050 = 8 + int(_4895.w);\n    float _5077;\n    float _5090;\n    float _5104;\n    for (int k = 0; k < _5050; k++)\n    {\n        float _5063 = float(k & 1);\n        float _5067 = float((k >> 1) & 1);\n        float _5071 = float((k >> 2) & 1);\n        if (_5063 > 0.5)\n        {\n            _5077 = _4970.x;\n        }\n        else\n        {\n            _5077 = 1.0 - _4970.x;\n        }\n        if (_5067 > 0.5)\n        {\n            _5090 = _4970.y;\n        }\n        else\n        {\n            _5090 = 1.0 - _4970.y;\n        }\n        if (_5071 > 0.5)\n        {\n            _5104 = _4970.z;\n        }\n        else\n        {\n            _5104 = 1.0 - _4970.z;\n        }\n        float _5114 = (_5077 * _5090) * _5104;\n        if (!(_5114 > 0.0))\n        {\n            continue;\n        }\n        vec3 _5127 = min(_4966 + vec3(_5063, _5067, _5071), _4957);\n        int _5147 = int(((_4890.x + _5127.x) + (_4885.x * (_5127.y + (_4885.y * _5127.z)))) + 0.5);\n        vec2 _5162 = vec2(float(_5147 % _4987) * 10.0, 1024.0 + (float(_5147 / _4987) * 11.0));\n        vec2 param_4 = _5162 + vec2(9.5, 10.5);\n        vec4 _5170 = fa_gi_fetch(param_4);\n        bool _5173 = _5170.y < 0.5;\n        bool _5182;\n        if (!_5173)\n        {\n            _5182 = _5170.x > _4895.y;\n        }\n        else\n        {\n            _5182 = _5173;\n        }\n        if (_5182)\n        {\n            continue;\n        }\n        vec3 _5194 = _4982 - (_4920 + (_5127 * _4913));\n        float _5197 = length(_5194);\n        vec3 _5203 = _5194 / vec3(max(_5197, 9.9999997473787516355514526367188e-05));\n        float _5213 = max(9.9999997473787516355514526367188e-05, (dot(-_5203, n) + 1.0) * 0.5);\n        float w = _5114 * (_5213 * _5213);\n        vec3 param_5 = _5203;\n        vec2 param_6 = (_5162 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _5233 = fa_gi_fetch(param_6);\n        float _5240 = _5197 / max(_4890.z, 9.9999997473787516355514526367188e-05);\n        float _5243 = _5233.x;\n        if (_5240 > _5243)\n        {\n            float _5256 = max(_5233.y - (_5243 * _5243), 0.0);\n            float _5261 = _5240 - _5243;\n            float _5270 = _5256 / max(_5256 + (_5261 * _5261), 9.9999999600419720025001879548654e-13);\n            w *= ((_5270 * _5270) * _5270);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _5162 + vec2(0.5, 10.5);\n        vec2 param_8 = _5162 + vec2(1.5, 10.5);\n        vec2 param_9 = _5162 + vec2(2.5, 10.5);\n        vec2 param_10 = _5162 + vec2(3.5, 10.5);\n        vec2 param_11 = _5162 + vec2(4.5, 10.5);\n        vec2 param_12 = _5162 + vec2(5.5, 10.5);\n        vec2 param_13 = _5162 + vec2(6.5, 10.5);\n        vec2 param_14 = _5162 + vec2(7.5, 10.5);\n        vec2 param_15 = _5162 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _4992)) + (fa_gi_fetch(param_9).xyz * _4996)) + (fa_gi_fetch(param_10).xyz * _5000)) + (fa_gi_fetch(param_11).xyz * _5007)) + (fa_gi_fetch(param_12).xyz * _5014)) + (fa_gi_fetch(param_13).xyz * _5023)) + (fa_gi_fetch(param_14).xyz * _5030)) + (fa_gi_fetch(param_15).xyz * _5043)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_4942 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _5398;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _5398 = _4895.x;\n    }\n    else\n    {\n        _5398 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_4890.w * _5398);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _5422 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _5427 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _5432 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _5432) && (k < 8); k++)\n    {\n        int param = _5427 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _5422;\n        vec3 _5457 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5462 = param_3 * left;\n        acc += (_5457 * _5462);\n        left -= _5462;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _5491 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5491;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _5533 = vec4(fa_world_pos, 1.0);\n        vec2 _5552 = vec2(dot(fa_mesh_fs_params[26], _5533), dot(fa_mesh_fs_params[27], _5533)) / vec2(max(dot(fa_mesh_fs_params[28], _5533), 9.9999997473787516355514526367188e-05));\n        float _5561;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5561 = (_5552.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5561 = 0.5 - (_5552.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_5552.x * 0.5) + 0.5, _5561) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4298;\n    if (fa_lm.z > 0.5)\n    {\n        _4298 = 0.0;\n    }\n    else\n    {\n        _4298 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4309 = _4298 < 1.0;\n    bool _4315;\n    if (_4309)\n    {\n        int param = li;\n        _4315 = fa_light_baked(param);\n    }\n    else\n    {\n        _4315 = _4309;\n    }\n    return _4315 ? _4298 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _617 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _630 = (c - (ru * hx)) - p;\n        vec3 _636 = ru * (2.0 * hx);\n        float _642 = max(dot(_636, _636), 9.9999999392252902907785028219223e-09);\n        float _646 = dot(_630, _636);\n        float t = clamp((-_646) / _642, 0.0, 1.0);\n        if (_617)\n        {\n            float _661 = dot(r, _636);\n            float _667 = _642 - (_661 * _661);\n            if (abs(_667) > (9.9999997473787516355514526367188e-06 * _642))\n            {\n                t = clamp(((dot(r, _630) * _661) - _646) / _667, 0.0, 1.0);\n            }\n        }\n        return (p + _630) + (_636 * t);\n    }\n    vec3 q = p;\n    float _699 = dot(r, axis);\n    bool _707;\n    if (_617)\n    {\n        _707 = abs(_699) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _707 = _617;\n    }\n    if (_707)\n    {\n        float _717 = dot(c - p, axis) / _699;\n        if (_717 > 0.0)\n        {\n            q = p + (r * _717);\n        }\n    }\n    vec3 _730 = q - c;\n    vec2 xy = vec2(dot(_730, ru), dot(_730, uu));\n    if (shape > 0.5)\n    {\n        float _745 = length(xy);\n        if (_745 > hx)\n        {\n            xy *= (hx / _745);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _537 = dot(d, right);\n    float _541 = dot(d, up);\n    float _552;\n    if (((_537 * _537) + (_541 * _541)) > 1.0000000133514319600180897396058e-10)\n    {\n        _552 = atan(_541, _537) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _552 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_552 - floor(_552)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _388 = abs(d);\n    float _390 = _388.x;\n    float _392 = _388.y;\n    bool _393 = _390 >= _392;\n    bool _401;\n    if (_393)\n    {\n        _401 = _390 >= _388.z;\n    }\n    else\n    {\n        _401 = _393;\n    }\n    int _402;\n    if (_401)\n    {\n        _402 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _416;\n        if (_392 >= _388.z)\n        {\n            _416 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _416 = (d.z > 0.0) ? 4 : 5;\n        }\n        _402 = _416;\n    }\n    return _402;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _783 = fa_light_base(param);\n    bool _787 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _783;\n    vec4 _791 = fa_light_texel(param_1);\n    int param_2 = _783 + 1;\n    vec4 _796 = fa_light_texel(param_2);\n    float _799 = _796.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _811 = _787 && (_799 > 2.5);\n    fa_light_is_area = _811;\n    bool _813 = _799 < 0.5;\n    vec3 l;\n    if (_813)\n    {\n        l = normalize(_791.xyz);\n        if (_787)\n        {\n            int param_3 = _783 + 6;\n            vec4 _827 = fa_light_texel(param_3);\n            if (_827.z > 0.5)\n            {\n                int param_4 = _783 + 4;\n                vec4 _837 = fa_light_texel(param_4);\n                int param_5 = _783 + 5;\n                vec4 _842 = fa_light_texel(param_5);\n                vec2 param_6 = _827.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _837.xyz) * _837.w, (-dot(world_pos, _842.xyz)) * _842.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _872 = _791.xyz;\n        vec3 _874 = _872 - world_pos;\n        vec3 to_light = _874;\n        float _877 = length(_874);\n        float reach = _877;\n        bool front = true;\n        if (_811)\n        {\n            int param_8 = _783 + 7;\n            reach = max(_877 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _783 + 4;\n            vec4 _901 = fa_light_texel(param_9);\n            int param_10 = _783 + 5;\n            vec4 _906 = fa_light_texel(param_10);\n            int param_11 = _783 + 6;\n            vec4 _911 = fa_light_texel(param_11);\n            float _912 = _911.w;\n            int param_12 = _783 + 2;\n            vec3 _919 = normalize(fa_light_texel(param_12).xyz);\n            bool _921 = _912 > 1.5;\n            bool _929;\n            if (!_921)\n            {\n                _929 = dot(_919, to_light) < 0.0;\n            }\n            else\n            {\n                _929 = _921;\n            }\n            front = _929;\n            vec3 r = vec3(0.0);\n            vec3 _938 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _942 = dot(n, n) > 0.5;\n            bool _950;\n            if (_942)\n            {\n                _950 = dot(_938, _938) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _950 = _942;\n            }\n            if (_950)\n            {\n                r = reflect(-normalize(_938), normalize(n));\n            }\n            vec3 param_13 = _872;\n            vec3 param_14 = _919;\n            vec3 param_15 = _901.xyz;\n            vec3 param_16 = _906.xyz;\n            float param_17 = _901.w;\n            float param_18 = _906.w;\n            float param_19 = _912;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _986 = length(to_light);\n        dist = _986;\n        l = to_light / vec3(max(_986, 9.9999997473787516355514526367188e-05));\n        float _1000 = reach / max(_791.w, 0.001000000047497451305389404296875);\n        float _1006 = clamp(1.0 - (_1000 * _1000), 0.0, 1.0);\n        float _1008;\n        if (front)\n        {\n            _1008 = _1006 * _1006;\n        }\n        else\n        {\n            _1008 = 0.0;\n        }\n        atten = _1008;\n        bool _1019 = _799 < 2.5;\n        if ((_799 > 1.5) && _1019)\n        {\n            int param_22 = _783 + 2;\n            vec4 _1027 = fa_light_texel(param_22);\n            float _1037 = _1027.w;\n            int param_23 = _783 + 3;\n            vec4 _1042 = fa_light_texel(param_23);\n            float _1043 = _1042.x;\n            float cos_inner = _1043;\n            if (_1043 > 1.5)\n            {\n                cos_inner = mix(_1037, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1037, cos_inner, dot(-l, normalize(_1027.xyz)));\n        }\n        if (_787 && (_799 < 1.5))\n        {\n            int param_24 = _783 + 6;\n            vec4 _1067 = fa_light_texel(param_24);\n            if (_1067.z > 0.5)\n            {\n                vec3 _1075 = -to_light;\n                int param_25 = _783 + 4;\n                int param_26 = _783 + 5;\n                vec3 _1089 = fa_light_texel(param_25).xyz;\n                vec3 _1093 = fa_light_texel(param_26).xyz;\n                vec3 _1102 = vec3(dot(_1075, _1089), dot(_1075, _1093), dot(_1075, cross(_1089, _1093)));\n                vec3 param_27 = _1102;\n                int _1106 = fa_cube_face(param_27);\n                int param_28 = _1106;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1133 = vec2(dot(_1102, cross(param_29, param_30)), dot(_1102, param_30)) / vec2(max(dot(_1102, param_29), 9.9999997473787516355514526367188e-05));\n                int _1137 = _1106 / 3;\n                vec2 param_31 = _1067.xy + (vec2(float(_1106 - (_1137 * 3)), float(_1137)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1133.x), 0.5 - (0.5 * _1133.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _783 + 7;\n            vec4 _1167 = fa_light_texel(param_33);\n            if (_1167.z > 0.5)\n            {\n                int param_34 = _783 + 2;\n                int param_35 = _783 + 4;\n                int param_36 = _783 + 5;\n                vec2 param_37 = _1167.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_787 && _1019)\n            {\n                int param_42 = _783 + 6;\n                vec4 _1214 = fa_light_texel(param_42);\n                int param_43 = _783 + 7;\n                vec4 _1219 = fa_light_texel(param_43);\n                bool _1222 = _1214.z > 0.5;\n                bool _1229;\n                if (!_1222)\n                {\n                    _1229 = _1219.z > 0.5;\n                }\n                else\n                {\n                    _1229 = _1222;\n                }\n                if (_1229)\n                {\n                    int param_44 = _783 + 2;\n                    vec4 _1236 = fa_light_texel(param_44);\n                    vec3 _1240 = normalize(_1236.xyz);\n                    int param_45 = _783 + 4;\n                    vec4 _1245 = fa_light_texel(param_45);\n                    int param_46 = _783 + 5;\n                    vec4 _1250 = fa_light_texel(param_46);\n                    if (_1222)\n                    {\n                        vec3 _1258 = -to_light;\n                        float _1265 = _1236.w;\n                        float _1281 = 0.5 / max(dot(_1258, _1240) * (sqrt(max(1.0 - (_1265 * _1265), 0.0)) / max(_1265, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1214.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1258, _1245.xyz) * _1281), 0.5 - (dot(_1258, _1250.xyz) * _1281));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1219.z > 0.5)\n                    {\n                        vec2 param_49 = _1219.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1240;\n                        vec3 param_52 = _1245.xyz;\n                        vec3 param_53 = _1250.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6282 = _796.xyz * atten;\n    if (_787)\n    {\n        _6282 *= fa_light_tint;\n    }\n    int _1349;\n    if (_813)\n    {\n        _1349 = 0;\n    }\n    else\n    {\n        _1349 = ((_799 > 1.5) && (_799 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6282, atten, 1.0, dist, _1349);\n}\n\nfloat fa_rt_local_tap(ivec2 p, ivec2 size, float d, float tol, float div, inout float best)\n{\n    vec4 _3310 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(p, ivec2(0), size - ivec2(1)), 0);\n    bool _3313 = _3310.w > 0.5;\n    bool _3323;\n    if (_3313)\n    {\n        _3323 = abs(d - _3310.x) <= tol;\n    }\n    else\n    {\n        _3323 = _3313;\n    }\n    if (_3323)\n    {\n        best = min(best, mod(floor(_3310.z / div), 256.0) * 0.0039215688593685626983642578125);\n    }\n    return best;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2138 = fa_shadow_depth(param, param_1);\n    float _2142;\n    if (conv.x < 0.5)\n    {\n        _2142 = _2138;\n    }\n    else\n    {\n        _2142 = (conv.y * conv.z) / (conv.z - (_2138 * (conv.z - conv.y)));\n    }\n    return _2142;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2188 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2194 = vec2(cos(_2188), sin(_2188));\n    vec2 dir = _2194;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2203;\n        if (k < 0.0)\n        {\n            _2203 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2203 = k;\n        }\n        float _2222 = clamp((_2203 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2241 = sqrt((float(i) + 0.5) * 0.0625) * _2222;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2241));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2255 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2255 < (zr - (_2241 * plane)))\n            {\n                sum += _2255;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2283 = sum / cnt;\n        float _2293;\n        if (k < 0.0)\n        {\n            _2293 = (-k) / max(_2283, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2293 = k;\n        }\n        radius = clamp(((max(zr - _2283, 0.0) * unit) * _2293) / texel_m, 1.5, 16.0);\n        dir = _2194;\n    }\n    float lit = 0.0;\n    int _2319 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2319; i_1++)\n    {\n        float _2338 = sqrt((float(i_1) + 0.5) / float(_2319)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2338));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2338 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2319);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2543 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2550;\n    if (!_2543)\n    {\n        _2550 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2550 = _2543;\n    }\n    if (_2550)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2563 = fa_light_texel(param);\n    float _2564 = _2563.x;\n    if (_2564 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2573 = int(_2564 + 0.5);\n    int param_1 = _2573;\n    vec4 _2577 = fa_light_texel(param_1);\n    int param_2 = _2573 + 1;\n    vec4 _2582 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2585 = _2577.y;\n    if (_2585 > 0.0)\n    {\n        float _2602 = 1.0 - smoothstep(0.75 * _2585, _2585, length(world - fa_shadows[27].xyz));\n        fade = _2602;\n        if (_2602 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2577.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2626 = (_2573 + 2) + (face * 6);\n    int param_4 = _2626;\n    int param_5 = _2626 + 1;\n    int param_6 = _2626 + 3;\n    vec4 _2640 = fa_light_texel(param_6);\n    int param_7 = _2626 + 4;\n    vec4 _2645 = fa_light_texel(param_7);\n    int param_8 = _2626 + 5;\n    vec4 _2650 = fa_light_texel(param_8);\n    float _2662 = _2650.x * max(dot(_2640, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2667 = clamp(dot(n, l), 0.0, 1.0);\n    float _2690 = clamp(dot(n, _2640.xyz), -1.0, 1.0);\n    float _2709 = min(sqrt(1.0 - (_2690 * _2690)) / max(abs(dot(n, world - lpos)) / max(dot(_2640, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2712 = _2582.y;\n    float _2714;\n    if (_2712 > 0.0)\n    {\n        _2714 = _2712;\n    }\n    else\n    {\n        _2714 = 1.5 * _2662;\n    }\n    vec4 _2734 = vec4(world + (n * (_2714 * sqrt(1.0 - (_2667 * _2667)))), 1.0);\n    float _2738 = dot(_2640, _2734);\n    float _2741 = _2650.y;\n    if (_2738 < _2741)\n    {\n        return 1.0;\n    }\n    vec2 _2756 = vec2(dot(fa_light_texel(param_4), _2734), dot(fa_light_texel(param_5), _2734)) / vec2(_2738);\n    float _2758 = _2756.x;\n    bool _2761 = _2758 < _2645.x;\n    bool _2770;\n    if (!_2761)\n    {\n        _2770 = _2758 > _2645.z;\n    }\n    else\n    {\n        _2770 = _2761;\n    }\n    bool _2779;\n    if (!_2770)\n    {\n        _2779 = _2756.y < _2645.y;\n    }\n    else\n    {\n        _2779 = _2770;\n    }\n    bool _2788;\n    if (!_2779)\n    {\n        _2788 = _2756.y > _2645.w;\n    }\n    else\n    {\n        _2788 = _2779;\n    }\n    if (_2788)\n    {\n        return 1.0;\n    }\n    float _2794 = _2582.x;\n    float _2796;\n    if (_2794 > 0.0)\n    {\n        _2796 = _2794;\n    }\n    else\n    {\n        _2796 = 1.5 * _2662;\n    }\n    vec2 param_9 = _2756;\n    vec4 param_10 = _2645;\n    float param_11 = _2738 - (_2796 * (1.0 + (0.5 * _2709)));\n    float param_12 = _2662;\n    float param_13 = 1.0;\n    float param_14 = _2650.z * 0.25;\n    float param_15 = (_2662 * min(_2709, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2741, _2650.z);\n    int param_17 = int(_2577.z + 0.5);\n    float param_18 = _2577.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3341 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3347;\n    if (_3341)\n    {\n        _3347 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3347 = _3341;\n    }\n    bool _3353;\n    if (_3347)\n    {\n        _3353 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3353 = _3347;\n    }\n    if (_3353)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3365 = fa_light_texel(param);\n        float _3366 = _3365.z;\n        if (_3366 > 0.5)\n        {\n            float _3379 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3385 = ((0.00200000009499490261077880859375 * _3379) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3391 = vec4(world, 1.0);\n            float _3396 = dot(fa_mesh_fs_params[28], _3391);\n            if (_3396 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3413 = vec2(dot(fa_mesh_fs_params[26], _3391), dot(fa_mesh_fs_params[27], _3391)) / vec2(_3396);\n                float _3418 = (_3413.x * 0.5) + 0.5;\n                float _3422;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3422 = (_3413.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3422 = 0.5 - (_3413.y * 0.5);\n                }\n                bool _3438 = _3418 >= 0.0;\n                bool _3444;\n                if (_3438)\n                {\n                    _3444 = _3418 < 1.0;\n                }\n                else\n                {\n                    _3444 = _3438;\n                }\n                bool _3450;\n                if (_3444)\n                {\n                    _3450 = _3422 >= 0.0;\n                }\n                else\n                {\n                    _3450 = _3444;\n                }\n                bool _3456;\n                if (_3450)\n                {\n                    _3456 = _3422 < 1.0;\n                }\n                else\n                {\n                    _3456 = _3450;\n                }\n                if (_3456)\n                {\n                    ivec2 _3463 = ivec2(fa_mesh_fs_params[24].zw);\n                    ivec2 _3474 = clamp(ivec2(vec2(_3418, _3422) * fa_mesh_fs_params[24].zw), ivec2(0), _3463 - ivec2(1));\n                    float _3478;\n                    if (_3366 < 1.5)\n                    {\n                        _3478 = 1.0;\n                    }\n                    else\n                    {\n                        _3478 = (_3366 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    vec4 _3494 = texelFetch(fa_screen_tex_fa_shadow_smp, _3474, 0);\n                    bool _3497 = _3494.w > 0.5;\n                    bool _3507;\n                    if (_3497)\n                    {\n                        _3507 = abs(_3379 - _3494.x) <= _3385;\n                    }\n                    else\n                    {\n                        _3507 = _3497;\n                    }\n                    if (_3507)\n                    {\n                        best = mod(floor(_3494.z / _3478), 256.0) * 0.0039215688593685626983642578125;\n                    }\n                    else\n                    {\n                        ivec2 param_1 = _3474 + ivec2(-1);\n                        ivec2 param_2 = _3463;\n                        float param_3 = _3379;\n                        float param_4 = _3385;\n                        float param_5 = _3478;\n                        float param_6 = best;\n                        float _3533 = fa_rt_local_tap(param_1, param_2, param_3, param_4, param_5, param_6);\n                        best = _3533;\n                        ivec2 param_7 = _3474 + ivec2(0, -1);\n                        ivec2 param_8 = _3463;\n                        float param_9 = _3379;\n                        float param_10 = _3385;\n                        float param_11 = _3478;\n                        float param_12 = _3533;\n                        float _3548 = fa_rt_local_tap(param_7, param_8, param_9, param_10, param_11, param_12);\n                        best = _3548;\n                        ivec2 param_13 = _3474 + ivec2(1, -1);\n                        ivec2 param_14 = _3463;\n                        float param_15 = _3379;\n                        float param_16 = _3385;\n                        float param_17 = _3478;\n                        float param_18 = _3548;\n                        float _3563 = fa_rt_local_tap(param_13, param_14, param_15, param_16, param_17, param_18);\n                        best = _3563;\n                        ivec2 param_19 = _3474 + ivec2(-1, 0);\n                        ivec2 param_20 = _3463;\n                        float param_21 = _3379;\n                        float param_22 = _3385;\n                        float param_23 = _3478;\n                        float param_24 = _3563;\n                        float _3578 = fa_rt_local_tap(param_19, param_20, param_21, param_22, param_23, param_24);\n                        best = _3578;\n                        ivec2 param_25 = _3474 + ivec2(1, 0);\n                        ivec2 param_26 = _3463;\n                        float param_27 = _3379;\n                        float param_28 = _3385;\n                        float param_29 = _3478;\n                        float param_30 = _3578;\n                        float _3593 = fa_rt_local_tap(param_25, param_26, param_27, param_28, param_29, param_30);\n                        best = _3593;\n                        ivec2 param_31 = _3474 + ivec2(-1, 1);\n                        ivec2 param_32 = _3463;\n                        float param_33 = _3379;\n                        float param_34 = _3385;\n                        float param_35 = _3478;\n                        float param_36 = _3593;\n                        float _3608 = fa_rt_local_tap(param_31, param_32, param_33, param_34, param_35, param_36);\n                        best = _3608;\n                        ivec2 param_37 = _3474 + ivec2(0, 1);\n                        ivec2 param_38 = _3463;\n                        float param_39 = _3379;\n                        float param_40 = _3385;\n                        float param_41 = _3478;\n                        float param_42 = _3608;\n                        float _3623 = fa_rt_local_tap(param_37, param_38, param_39, param_40, param_41, param_42);\n                        best = _3623;\n                        ivec2 param_43 = _3474 + ivec2(1);\n                        ivec2 param_44 = _3463;\n                        float param_45 = _3379;\n                        float param_46 = _3385;\n                        float param_47 = _3478;\n                        float param_48 = _3623;\n                        float _3638 = fa_rt_local_tap(param_43, param_44, param_45, param_46, param_47, param_48);\n                        best = _3638;\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3646;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_49 = li;\n                            vec3 param_50 = lpos;\n                            vec3 param_51 = world;\n                            vec3 param_52 = n;\n                            vec3 param_53 = l;\n                            _3646 = min(best, fa_shadow_local(param_49, param_50, param_51, param_52, param_53));\n                        }\n                        else\n                        {\n                            _3646 = best;\n                        }\n                        return _3646;\n                    }\n                }\n            }\n            float _3669;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_54 = li;\n                vec3 param_55 = lpos;\n                vec3 param_56 = world;\n                vec3 param_57 = n;\n                vec3 param_58 = l;\n                _3669 = fa_shadow_local(param_54, param_55, param_56, param_57, param_58);\n            }\n            else\n            {\n                _3669 = 1.0;\n            }\n            return _3669;\n        }\n    }\n    int param_59 = li;\n    vec3 param_60 = lpos;\n    vec3 param_61 = world;\n    vec3 param_62 = n;\n    vec3 param_63 = l;\n    return fa_shadow_local(param_59, param_60, param_61, param_62, param_63);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2081;\n    if (i == 0)\n    {\n        _2081 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2097;\n        if (i == 1)\n        {\n            _2097 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2105;\n            if (i == 2)\n            {\n                _2105 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2105 = fa_shadows[24].w;\n            }\n            _2097 = _2105;\n        }\n        _2081 = _2097;\n    }\n    return _2081;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2384 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2389 = clamp(dot(n, l), 0.0, 1.0);\n    float _2395 = sqrt(1.0 - (_2389 * _2389));\n    float _2403 = min(_2395 / max(_2389, 0.20000000298023223876953125), 4.0);\n    float _2408;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2408 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2408 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2433 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2408 * _2395)), 1.0);\n    float _2440 = _2433.x;\n    bool _2443 = _2440 < fa_shadows[ci * 1 + 16].x;\n    bool _2452;\n    if (!_2443)\n    {\n        _2452 = _2440 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2452 = _2443;\n    }\n    bool _2461;\n    if (!_2452)\n    {\n        _2461 = _2433.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2461 = _2452;\n    }\n    bool _2470;\n    if (!_2461)\n    {\n        _2470 = _2433.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2470 = _2461;\n    }\n    bool _2477;\n    if (!_2470)\n    {\n        _2477 = _2433.z > 1.0;\n    }\n    else\n    {\n        _2477 = _2470;\n    }\n    if (_2477)\n    {\n        return -1.0;\n    }\n    float _2485;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2485 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2485 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2433.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2433.z - ((_2485 * (1.0 + (0.5 * _2403))) / _2384);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2384;\n    float param_5 = _2384 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2403, 3.0)) * 0.5) / _2384;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2863 = int(fa_shadows[25].x + 0.5);\n    if (_2863 < 1)\n    {\n        return 1.0;\n    }\n    float _2878 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2863 - 1;\n    if (_2878 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2890 = _2863 > 1;\n    bool _2897;\n    if (_2890)\n    {\n        _2897 = _2878 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2897 = _2890;\n    }\n    if (_2897)\n    {\n        ci = 1;\n    }\n    bool _2901 = _2863 > 2;\n    bool _2908;\n    if (_2901)\n    {\n        _2908 = _2878 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2908 = _2901;\n    }\n    if (_2908)\n    {\n        ci = 2;\n    }\n    bool _2912 = _2863 > 3;\n    bool _2919;\n    if (_2912)\n    {\n        _2919 = _2878 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2919 = _2912;\n    }\n    if (_2919)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2930 = min(_2863, 4);\n    float _2971;\n    for (int c = ci; c < _2930; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2950 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2950;\n            break;\n        }\n        if (_2950 < 0.0)\n        {\n            continue;\n        }\n        s = _2950;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2971 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2971 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _2990 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2971, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2878 - (fa_shadow_split_at(param_7) - _2990)) / _2990, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3022;\n        if ((ci + 1) < _2863)\n        {\n            _3022 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3022 = 1.0;\n        }\n        s = mix(s, _3022, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3127 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3133;\n    if (_3127)\n    {\n        _3133 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3133 = _3127;\n    }\n    if (_3133)\n    {\n        float _3147 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3155 = vec4(fa_world_pos, 1.0);\n        float _3161 = dot(fa_mesh_fs_params[28], _3155);\n        if (_3161 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3180 = vec2(dot(fa_mesh_fs_params[26], _3155), dot(fa_mesh_fs_params[27], _3155)) / vec2(_3161);\n            float _3185 = (_3180.x * 0.5) + 0.5;\n            float _3189;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3189 = (_3180.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3189 = 0.5 - (_3180.y * 0.5);\n            }\n            bool _3205 = _3185 >= 0.0;\n            bool _3211;\n            if (_3205)\n            {\n                _3211 = _3185 < 1.0;\n            }\n            else\n            {\n                _3211 = _3205;\n            }\n            bool _3217;\n            if (_3211)\n            {\n                _3217 = _3189 >= 0.0;\n            }\n            else\n            {\n                _3217 = _3211;\n            }\n            bool _3223;\n            if (_3217)\n            {\n                _3223 = _3189 < 1.0;\n            }\n            else\n            {\n                _3223 = _3217;\n            }\n            if (_3223)\n            {\n                vec4 _3248 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3185, _3189) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3251 = _3248.w > 0.5;\n                bool _3267;\n                if (_3251)\n                {\n                    _3267 = abs(_3147 - _3248.x) <= (((0.00200000009499490261077880859375 * _3147) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3267 = _3251;\n                }\n                if (_3267)\n                {\n                    float _3273;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3273 = min(_3248.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3273 = _3248.y;\n                    }\n                    return _3273;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4040 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4047;\n    if (!_4040)\n    {\n        _4047 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4047 = _4040;\n    }\n    if (_4047)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4060 = fa_light_texel(param);\n    float _4061 = _4060.y;\n    float len = _4061;\n    if (_4061 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4073 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4082 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4073);\n    if (_4082 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4088 = len;\n    float _4091 = min(_4088, 0.89999997615814208984375 * dist);\n    len = _4091;\n    float _4097 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4073);\n    float _4102 = _4097 + (0.5 * _4091);\n    vec3 _4108 = world + (gn * _4097);\n    float _4110 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4172;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4126 = (float(k) + _4110) * 0.083333335816860198974609375;\n        vec3 _4134 = _4108 + (l * (_4126 * len));\n        vec4 _4140 = vec4(_4134, 1.0);\n        float _4145 = dot(fa_mesh_fs_params[28], _4140);\n        if (_4145 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4163 = vec2(dot(fa_mesh_fs_params[26], _4140), dot(fa_mesh_fs_params[27], _4140)) / vec2(_4145);\n        float _4167 = _4163.x * 0.5;\n        float _4168 = _4167 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4172 = (_4163.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4172 = 0.5 - (_4163.y * 0.5);\n        }\n        bool _4188 = _4168 < 0.0;\n        bool _4195;\n        if (!_4188)\n        {\n            _4195 = _4168 >= 1.0;\n        }\n        else\n        {\n            _4195 = _4188;\n        }\n        bool _4202;\n        if (!_4195)\n        {\n            _4202 = _4172 < 0.0;\n        }\n        else\n        {\n            _4202 = _4195;\n        }\n        bool _4209;\n        if (!_4202)\n        {\n            _4209 = _4172 >= 1.0;\n        }\n        else\n        {\n            _4209 = _4202;\n        }\n        if (_4209)\n        {\n            break;\n        }\n        vec4 _4233 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4168, _4172) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4233.w < 0.5)\n        {\n            continue;\n        }\n        float _4251 = (dot(fa_mesh_fs_params[29].xyz, _4134) + fa_mesh_fs_params[29].w) - _4233.x;\n        if ((_4251 > _4097) && (_4251 < _4102))\n        {\n            occ = max(occ, (1.0 - (_4126 * _4126)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4168, 0.5 - _4167), min(_4172, 1.0 - _4172))));\n        }\n    }\n    return 1.0 - (occ * _4082);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4383 = fa_baked_keep(param);\n    if (_4383 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4409 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6308 = _4409.color;\n    float _6309 = _4409.attenuation;\n    float _6310 = _4409.shadow;\n    bool _4412 = _4409.type == 0;\n    if (_4412 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4409.direction;\n        float _4423 = fa_shadow_factor(param_5, param_6);\n        _6310 = _4423;\n        _6308 *= _4423;\n    }\n    else\n    {\n        bool _4434 = _4409.type != 0;\n        bool _4440;\n        if (_4434)\n        {\n            _4440 = _6309 > 0.0;\n        }\n        else\n        {\n            _4440 = _4434;\n        }\n        if (_4440)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4409.direction;\n            float _4459 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6310 = _4459;\n            _6308 *= _4459;\n        }\n    }\n    bool _4469 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4475;\n    if (_4469)\n    {\n        _4475 = _6309 > 0.0;\n    }\n    else\n    {\n        _4475 = _4469;\n    }\n    if (_4475)\n    {\n        float _4482;\n        if (_4412)\n        {\n            _4482 = 1000000000.0;\n        }\n        else\n        {\n            _4482 = _4409._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4409.direction;\n        float param_18 = _4482;\n        float _4500 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6310 *= _4500;\n        _6308 *= _4500;\n    }\n    float _4513 = _6309;\n    float _4514 = _4513 * _4383;\n    _6309 = _4514;\n    vec3 _4518 = _6308;\n    vec3 _4519 = _4518 * _4383;\n    _6308 = _4519;\n    return LightSample(_4409.direction, _4519, _4514, _6310, _4409._distance, _4409.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3050 = int(fa_shadows[25].x + 0.5);\n    float _3060 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3065 = _3050 > 0;\n    bool _3074;\n    if (_3065)\n    {\n        int param = _3050 - 1;\n        _3074 = _3060 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3074 = _3065;\n    }\n    if (_3074)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3080 = _3050 > 1;\n        bool _3087;\n        if (_3080)\n        {\n            _3087 = _3060 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3087 = _3080;\n        }\n        if (_3087)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3093 = _3050 > 2;\n        bool _3100;\n        if (_3093)\n        {\n            _3100 = _3060 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3100 = _3093;\n        }\n        if (_3100)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3106 = _3050 > 3;\n        bool _3113;\n        if (_3106)\n        {\n            _3113 = _3060 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3113 = _3106;\n        }\n        if (_3113)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _6100 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6100 = -_6100;\n    }\n    vec3 _5674 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6100, fa_world_tangent, fa_uv, fa_vertex_color, _5674, gl_FrontFacing);\n    Surface _5682 = fa_standard_surface(param_1);\n    vec3 _6139 = _5682.albedo;\n    float _6140 = _5682.alpha;\n    vec3 _6141 = _5682.normal;\n    float _6142 = _5682.metallic;\n    float _6143 = _5682.roughness;\n    float _6144 = _5682.occlusion;\n    vec3 _6145 = _5682.emission;\n    float _6146 = _5682.clearcoat;\n    float _6147 = _5682.clearcoat_roughness;\n    vec3 _6148 = _5682.sheen_color;\n    float _6149 = _5682.sheen_roughness;\n    float _6150 = _5682.anisotropy;\n    float _6151 = _5682.anisotropy_rotation;\n    float _6152 = _5682.specular;\n    float _6153 = _5682.ior;\n    vec3 _6154 = _5682.specular_color;\n    float _6155 = _5682.transmission;\n    float _6156 = _5682.thickness;\n    vec3 _6157 = _5682.attenuation_color;\n    float _6158 = _5682.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6100, fa_world_tangent, fa_uv, fa_vertex_color, _5674, gl_FrontFacing);\n    Surface param_3 = _5682;\n    surface(param_2, param_3);\n    _6139 = param_3.albedo;\n    _6140 = param_3.alpha;\n    _6141 = param_3.normal;\n    _6142 = param_3.metallic;\n    _6143 = param_3.roughness;\n    _6144 = param_3.occlusion;\n    _6145 = param_3.emission;\n    _6146 = param_3.clearcoat;\n    _6147 = param_3.clearcoat_roughness;\n    _6148 = param_3.sheen_color;\n    _6149 = param_3.sheen_roughness;\n    _6150 = param_3.anisotropy;\n    _6151 = param_3.anisotropy_rotation;\n    _6152 = param_3.specular;\n    _6153 = param_3.ior;\n    _6154 = param_3.specular_color;\n    _6155 = param_3.transmission;\n    _6156 = param_3.thickness;\n    _6157 = param_3.attenuation_color;\n    _6158 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6100;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6139 = param_6;\n    _6141 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6139;\n    }\n    else\n    {\n        vec3 _5721 = _6141;\n        vec3 _5722 = normalize(_5721);\n        _6141 = _5722;\n        vec3 param_8 = _5722;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _6100, fa_world_tangent, fa_uv, fa_vertex_color, _5674, gl_FrontFacing);\n        Surface param_10 = Surface(_6139, _6140, _6141, _6142, _6143, _6144, _6145, _6146, _6147, _6148, _6149, _6150, _6151, _6152, _6153, _6154, _6155, _6156, _6157, _6158);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _5741 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5741; ln++)\n        {\n            int param_12 = ln;\n            int _5754 = fa_cl_light(param_12);\n            int param_13 = _5754;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _5754;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _6100;\n            LightSample _5770 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _6100, fa_world_tangent, fa_uv, fa_vertex_color, _5674, gl_FrontFacing);\n            Surface param_18 = Surface(_6139, _6140, _6141, _6142, _6143, _6144, _6145, _6146, _6147, _6148, _6149, _6150, _6151, _6152, _6153, _6154, _6155, _6156, _6157, _6158);\n            LightSample param_19 = _5770;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _5785 = result;\n    vec3 _5786 = _5785 + _6145;\n    result = _5786;\n    vec3 param_20 = _5786;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5795 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5802;\n    if (!_5795)\n    {\n        _5802 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5802 = _5795;\n    }\n    if (_5802)\n    {\n        vec3 _5811 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5817 = dot(_5811, fa_mesh_fs_params[9].xyz);\n        bool _5821 = fa_mesh_fs_params[9].w > 0.5;\n        float _5822;\n        if (_5821)\n        {\n            _5822 = _5817;\n        }\n        else\n        {\n            _5822 = length(_5811);\n        }\n        float _5834 = _5822 - fa_mesh_fs_params[8].x;\n        if (_5834 > 0.0)\n        {\n            float _5843 = fa_mesh_fs_params[7].w * _5834;\n            float tau = _5843 * _5843;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5859;\n                if (_5821)\n                {\n                    _5859 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5817);\n                }\n                else\n                {\n                    _5859 = fa_mesh_fs_params[0].y;\n                }\n                float _5880 = mix(_5859, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5822, 0.0, 1.0));\n                float _5884 = fa_world_pos.y - _5880;\n                float _5889 = _5880 - fa_mesh_fs_params[8].z;\n                float _5894 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5897 = _5889 <= 0.0;\n                bool _5898 = !_5897;\n                bool _5904;\n                if (_5898)\n                {\n                    _5904 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5904 = _5897;\n                }\n                float _5905;\n                if (_5904)\n                {\n                    _5905 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5905 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5889, 80.0));\n                }\n                bool _5932;\n                if (_5898)\n                {\n                    _5932 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5932 = _5897;\n                }\n                float _5933;\n                if (_5932)\n                {\n                    _5933 = fa_mesh_fs_params[8].y * _5889;\n                }\n                else\n                {\n                    _5933 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5889, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5958 = _5894 <= 0.0;\n                bool _5965;\n                if (!_5958)\n                {\n                    _5965 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5965 = _5958;\n                }\n                float _5966;\n                if (_5965)\n                {\n                    _5966 = fa_mesh_fs_params[8].y * _5894;\n                }\n                else\n                {\n                    _5966 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5894, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5993;\n                if (abs(_5884) < 0.001000000047497451305389404296875)\n                {\n                    _5993 = _5905;\n                }\n                else\n                {\n                    _5993 = (_5966 - _5933) / _5884;\n                }\n                tau += (_5834 * max(_5993, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6140);\n}\n\n",
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
            "inst_name": "_439",
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
            "inst_name": "_2091",
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
