{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "4f7d190a643df7eea422f9bce37d2bb8920145f92f7e586baf62c54f579868ea",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1357 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1364;\n    if (!_1357)\n    {\n        _1364 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1364 = _1357;\n    }\n    bool _1372;\n    if (!_1364)\n    {\n        _1372 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1372 = _1364;\n    }\n    bool _1379;\n    if (!_1372)\n    {\n        _1379 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1379 = _1372;\n    }\n    bool _1386;\n    if (!_1379)\n    {\n        _1386 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1386 = _1379;\n    }\n    if (_1386)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1396 = vec4(world_pos, 1.0);\n    float _1402 = dot(fa_mesh_fs_params[16], _1396);\n    if (!(_1402 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1424 = vec2(dot(fa_mesh_fs_params[14], _1396), dot(fa_mesh_fs_params[15], _1396)) / vec2(_1402);\n    int _1428 = int(fa_mesh_fs_params[18].x);\n    int _1432 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1432) + clamp(int(floor(((_1424.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1432 - 1)) * _1428)) + clamp(int(floor(((_1424.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1428 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1508 = fa_cluster_texel(param);\n    return ivec2(int(_1508.x), int(_1508.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _4208 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _4211 = fwidth(_4208);\n    bool _4214 = fa_mesh_fs_params[25].y > 0.5;\n    bool _4221;\n    if (!_4214)\n    {\n        _4221 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _4221 = _4214;\n    }\n    if (_4221)\n    {\n        fa_rt_slope = min(1.5 * _4211, 0.100000001490116119384765625 * _4208);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4237 = fa_cluster_lookup(param);\n    fa_cl_slot = _4237.x;\n    fa_cl_local = _4237.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4445 = fa_linear_to_srgb(param);\n        c = _4445;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4453 = fa_srgb_to_linear(param_1);\n            c = _4453;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _312;\n    if (i.front_facing)\n    {\n        _312 = i.world_normal;\n    }\n    else\n    {\n        _312 = -i.world_normal;\n    }\n    vec3 _336 = normalize(i.world_tangent.xyz - (_312 * dot(_312, i.world_tangent.xyz)));\n    vec3 _363 = normalize(((_336 * m.x) + ((cross(_312, _336) * i.world_tangent.w) * m.y)) + (_312 * m.z));\n    vec3 _366;\n    if (i.front_facing)\n    {\n        _366 = _363;\n    }\n    else\n    {\n        _366 = -_363;\n    }\n    return _366;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4485 = fa_tex_fix(param_2, param_3);\n    vec4 _6390 = base_t;\n    _6390.x = _4485.x;\n    _6390.y = _4485.y;\n    _6390.z = _4485.z;\n    base_t = _6390;\n    vec4 _4499 = (_6390 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6206 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4533 = fa_tex_fix(param_6, param_7);\n        vec3 _4536 = (_4533 * 2.0) - vec3(1.0);\n        vec2 _4541 = _4536.xy * fa_mesh_fs_params[6].x;\n        vec3 _6398 = _4536;\n        _6398.x = _4541.x;\n        _6398.y = _4541.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6398;\n        _6206 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4571 = fa_tex_fix(param_12, param_13);\n    vec4 _6401 = mrt;\n    _6401.x = _4571.x;\n    _6401.y = _4571.y;\n    _6401.z = _4571.z;\n    mrt = _6401;\n    vec4 _4601 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4601.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4612 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4644 = fa_tex_fix(param_20, param_21);\n    float _6211 = fa_mesh_fs_params[20].x;\n    float _6212 = fa_mesh_fs_params[20].y;\n    float _6215 = fa_mesh_fs_params[20].z;\n    float _6214 = fa_mesh_fs_params[21].w;\n    float _6217 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6211 *= _4612.y;\n            _6212 *= _4612.z;\n            _6214 *= _4601.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6215 *= mrt.x;\n            _6217 *= mrt.w;\n        }\n    }\n    return Surface(_4499.xyz, _4499.w, _6206, clamp(fa_mesh_fs_params[5].x * _4571.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4571.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4612.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4644), _6211, _6212, fa_mesh_fs_params[21].xyz, _6214, _6215, fa_mesh_fs_params[20].w, _6217, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1588 = rect.zw - rect.xy;\n    vec2 _1592 = _1588 * atlas;\n    vec2 _1596 = ddx * _1592;\n    vec2 _1600 = ddy * _1592;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1588), clamp(0.5 * log2(max(max(dot(_1596, _1596), dot(_1600, _1600)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1633 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1640;\n    if (!_1633)\n    {\n        _1640 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1640 = _1633;\n    }\n    if (_1640)\n    {\n        return;\n    }\n    vec3 _1646 = dFdx(world_pos);\n    vec3 _1649 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1653 = fa_cluster_texel(param);\n    int _1657 = int(_1653.w);\n    if (_1657 < 1)\n    {\n        return;\n    }\n    int _1667 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1667;\n    vec4 _1671 = fa_light_texel(param_1);\n    vec2 _1674 = _1671.yz;\n    int _1678 = int(_1671.w);\n    int param_2 = _1667 + 1;\n    vec4 _1683 = fa_light_texel(param_2);\n    float _1684 = _1683.x;\n    int _1690 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1694 = int(_1653.z);\n    vec3 _1959;\n    for (int k = 0; k < _1657; k++)\n    {\n        int _1707 = _1694 + k;\n        int param_3 = _1678 + (_1707 >> 2);\n        int _1724 = (_1667 + 2) + (int(fa_light_texel(param_3)[_1707 & 3]) * 7);\n        int param_4 = _1724 + 6;\n        vec4 _1729 = fa_light_texel(param_4);\n        if (((int(_1729.w + 0.5) >> _1690) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1724;\n        vec4 _1744 = fa_light_texel(param_5);\n        int param_6 = _1724 + 1;\n        vec4 _1749 = fa_light_texel(param_6);\n        int param_7 = _1724 + 2;\n        vec4 _1754 = fa_light_texel(param_7);\n        vec3 _1757 = _1744.xyz;\n        float _1762 = dot(_1757, world_pos) + _1744.w;\n        vec3 _1764 = _1749.xyz;\n        float _1769 = dot(_1764, world_pos) + _1749.w;\n        vec3 _1771 = _1754.xyz;\n        float _1776 = dot(_1771, world_pos) + _1754.w;\n        bool _1781 = abs(_1762) > 0.5;\n        bool _1789;\n        if (!_1781)\n        {\n            _1789 = abs(_1769) > 0.5;\n        }\n        else\n        {\n            _1789 = _1781;\n        }\n        bool _1797;\n        if (!_1789)\n        {\n            _1797 = abs(_1776) > 0.5;\n        }\n        else\n        {\n            _1797 = _1789;\n        }\n        if (_1797)\n        {\n            continue;\n        }\n        float _1812 = clamp(dot(geo_normal, normalize(_1771)) * _1729.z, 0.0, 1.0);\n        if (_1812 <= 0.0)\n        {\n            continue;\n        }\n        float _1832 = (clamp((0.5 - abs(_1776)) * 10.0, 0.0, 1.0) * _1812) * _1729.x;\n        vec2 _1840 = vec2(_1762 + 0.5, 0.5 - _1769);\n        vec2 _1850 = vec2(dot(_1757, _1646), dot(_1764, _1646));\n        vec2 _1860 = vec2(dot(_1757, _1649), dot(_1764, _1649));\n        int param_8 = _1724 + 5;\n        vec4 _1865 = fa_light_texel(param_8);\n        int param_9 = _1724 + 3;\n        vec4 _1870 = fa_light_texel(param_9);\n        int param_10 = _1724 + 4;\n        vec4 _1875 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1865.xyz;\n        bool _1885 = _1870.z > _1870.x;\n        if (_1885)\n        {\n            vec4 param_11 = _1870;\n            vec2 param_12 = _1840;\n            vec2 param_13 = _1674;\n            vec2 param_14 = _1850;\n            vec2 param_15 = _1860;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1684 > 0.5) && (_1684 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1911 = fa_dc_to_linear(param_16);\n                vec4 _6294 = tx;\n                _6294.x = _1911.x;\n                _6294.y = _1911.y;\n                _6294.z = _1911.z;\n                tx = _6294;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1832 * tex_a) * _1865.w, 0.0, 1.0)));\n        if (_1875.z > _1875.x)\n        {\n            vec4 param_17 = _1875;\n            vec2 param_18 = _1840;\n            vec2 param_19 = _1674;\n            vec2 param_20 = _1850;\n            vec2 param_21 = _1860;\n            vec4 _1955 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1684 > 1.5)\n            {\n                vec3 param_22 = _1955.xyz;\n                vec3 _1965 = fa_dc_to_srgb(param_22);\n                _1959 = _1965;\n            }\n            else\n            {\n                _1959 = _1955.xyz;\n            }\n            vec3 _1974 = (_1959 * 2.0) - vec3(1.0);\n            vec2 _1979 = _1974.xy * _1729.y;\n            vec3 _2001 = (normalize(_1757) * _1979.x) + (normalize(_1764) * _1979.y);\n            vec3 _2004 = normalize(normal);\n            normal = normalize(mix(_2004, normalize((_2004 * max(_1974.z, 0.0500000007450580596923828125)) + (_2001 - (_2004 * dot(_2004, _2001)))), vec3(clamp(_1832 * (_1885 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3672 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3672;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3781 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3787 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3781 > 0.0005000000237487256526947021484375)\n    {\n        if (_3787)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3781;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3781;\n        }\n    }\n    bool _3838 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3838)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3869 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3869)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3787 || _3838) || _3869)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3692 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3695 = _3692.x;\n    float _3697 = _3692.z;\n    vec2 e = vec2(_3695, _3697);\n    if (_3692.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3697)) * ((_3695 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3695)) * ((_3697 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _4758 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _4763 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _4768 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _4773 = fa_light_texel(param_3);\n    bool _4776 = _4773.z < 0.5;\n    bool _4784;\n    if (!_4776)\n    {\n        _4784 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _4784 = _4776;\n    }\n    if (_4784)\n    {\n        return vec3(0.0);\n    }\n    float _4791 = max(_4758.w, 9.9999997473787516355514526367188e-05);\n    vec3 _4794 = _4763.xyz;\n    vec3 _4798 = _4758.xyz;\n    vec3 _4802 = (fa_world_pos - _4798) / vec3(_4791);\n    vec3 _4811 = min(_4802 + vec3(0.5), (_4794 - vec3(0.5)) - _4802);\n    float _4820 = min(_4811.x, min(_4811.y, _4811.z));\n    if (!(_4820 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4835 = _4794 - vec3(1.0);\n    vec3 _4836 = clamp(_4802, vec3(0.0), _4835);\n    vec3 _4844 = min(floor(_4836), max(_4794 - vec3(2.0), vec3(0.0)));\n    vec3 _4848 = _4836 - _4844;\n    vec3 _4860 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _4791));\n    int _4865 = int(_4768.y + 0.5);\n    float _4870 = 0.3257350027561187744140625 * n.y;\n    float _4874 = 0.3257350027561187744140625 * n.z;\n    float _4878 = 0.3257350027561187744140625 * n.x;\n    float _4885 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _4892 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _4901 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _4908 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _4921 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _4928 = 8 + int(_4773.w);\n    float _4955;\n    float _4968;\n    float _4982;\n    for (int k = 0; k < _4928; k++)\n    {\n        float _4941 = float(k & 1);\n        float _4945 = float((k >> 1) & 1);\n        float _4949 = float((k >> 2) & 1);\n        if (_4941 > 0.5)\n        {\n            _4955 = _4848.x;\n        }\n        else\n        {\n            _4955 = 1.0 - _4848.x;\n        }\n        if (_4945 > 0.5)\n        {\n            _4968 = _4848.y;\n        }\n        else\n        {\n            _4968 = 1.0 - _4848.y;\n        }\n        if (_4949 > 0.5)\n        {\n            _4982 = _4848.z;\n        }\n        else\n        {\n            _4982 = 1.0 - _4848.z;\n        }\n        float _4992 = (_4955 * _4968) * _4982;\n        if (!(_4992 > 0.0))\n        {\n            continue;\n        }\n        vec3 _5005 = min(_4844 + vec3(_4941, _4945, _4949), _4835);\n        int _5025 = int(((_4768.x + _5005.x) + (_4763.x * (_5005.y + (_4763.y * _5005.z)))) + 0.5);\n        vec2 _5040 = vec2(float(_5025 % _4865) * 10.0, 1024.0 + (float(_5025 / _4865) * 11.0));\n        vec2 param_4 = _5040 + vec2(9.5, 10.5);\n        vec4 _5048 = fa_gi_fetch(param_4);\n        bool _5051 = _5048.y < 0.5;\n        bool _5060;\n        if (!_5051)\n        {\n            _5060 = _5048.x > _4773.y;\n        }\n        else\n        {\n            _5060 = _5051;\n        }\n        if (_5060)\n        {\n            continue;\n        }\n        vec3 _5072 = _4860 - (_4798 + (_5005 * _4791));\n        float _5075 = length(_5072);\n        vec3 _5081 = _5072 / vec3(max(_5075, 9.9999997473787516355514526367188e-05));\n        float _5091 = max(9.9999997473787516355514526367188e-05, (dot(-_5081, n) + 1.0) * 0.5);\n        float w = _4992 * (_5091 * _5091);\n        vec3 param_5 = _5081;\n        vec2 param_6 = (_5040 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _5111 = fa_gi_fetch(param_6);\n        float _5118 = _5075 / max(_4768.z, 9.9999997473787516355514526367188e-05);\n        float _5121 = _5111.x;\n        if (_5118 > _5121)\n        {\n            float _5134 = max(_5111.y - (_5121 * _5121), 0.0);\n            float _5139 = _5118 - _5121;\n            float _5148 = _5134 / max(_5134 + (_5139 * _5139), 9.9999999600419720025001879548654e-13);\n            w *= ((_5148 * _5148) * _5148);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _5040 + vec2(0.5, 10.5);\n        vec2 param_8 = _5040 + vec2(1.5, 10.5);\n        vec2 param_9 = _5040 + vec2(2.5, 10.5);\n        vec2 param_10 = _5040 + vec2(3.5, 10.5);\n        vec2 param_11 = _5040 + vec2(4.5, 10.5);\n        vec2 param_12 = _5040 + vec2(5.5, 10.5);\n        vec2 param_13 = _5040 + vec2(6.5, 10.5);\n        vec2 param_14 = _5040 + vec2(7.5, 10.5);\n        vec2 param_15 = _5040 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _4870)) + (fa_gi_fetch(param_9).xyz * _4874)) + (fa_gi_fetch(param_10).xyz * _4878)) + (fa_gi_fetch(param_11).xyz * _4885)) + (fa_gi_fetch(param_12).xyz * _4892)) + (fa_gi_fetch(param_13).xyz * _4901)) + (fa_gi_fetch(param_14).xyz * _4908)) + (fa_gi_fetch(param_15).xyz * _4921)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_4820 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _5276;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _5276 = _4773.x;\n    }\n    else\n    {\n        _5276 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_4768.w * _5276);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _5300 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _5305 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _5310 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _5310) && (k < 8); k++)\n    {\n        int param = _5305 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _5300;\n        vec3 _5335 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5340 = param_3 * left;\n        acc += (_5335 * _5340);\n        left -= _5340;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _5369 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5369;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _5411 = vec4(fa_world_pos, 1.0);\n        vec2 _5430 = vec2(dot(fa_mesh_fs_params[26], _5411), dot(fa_mesh_fs_params[27], _5411)) / vec2(max(dot(fa_mesh_fs_params[28], _5411), 9.9999997473787516355514526367188e-05));\n        float _5439;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5439 = (_5430.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5439 = 0.5 - (_5430.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_5430.x * 0.5) + 0.5, _5439) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return ambientColor;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4178;\n    if (fa_lm.z > 0.5)\n    {\n        _4178 = 0.0;\n    }\n    else\n    {\n        _4178 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4189 = _4178 < 1.0;\n    bool _4195;\n    if (_4189)\n    {\n        int param = li;\n        _4195 = fa_light_baked(param);\n    }\n    else\n    {\n        _4195 = _4189;\n    }\n    return _4195 ? _4178 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _607 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _620 = (c - (ru * hx)) - p;\n        vec3 _626 = ru * (2.0 * hx);\n        float _632 = max(dot(_626, _626), 9.9999999392252902907785028219223e-09);\n        float _636 = dot(_620, _626);\n        float t = clamp((-_636) / _632, 0.0, 1.0);\n        if (_607)\n        {\n            float _651 = dot(r, _626);\n            float _657 = _632 - (_651 * _651);\n            if (abs(_657) > (9.9999997473787516355514526367188e-06 * _632))\n            {\n                t = clamp(((dot(r, _620) * _651) - _636) / _657, 0.0, 1.0);\n            }\n        }\n        return (p + _620) + (_626 * t);\n    }\n    vec3 q = p;\n    float _689 = dot(r, axis);\n    bool _697;\n    if (_607)\n    {\n        _697 = abs(_689) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _697 = _607;\n    }\n    if (_697)\n    {\n        float _707 = dot(c - p, axis) / _689;\n        if (_707 > 0.0)\n        {\n            q = p + (r * _707);\n        }\n    }\n    vec3 _720 = q - c;\n    vec2 xy = vec2(dot(_720, ru), dot(_720, uu));\n    if (shape > 0.5)\n    {\n        float _735 = length(xy);\n        if (_735 > hx)\n        {\n            xy *= (hx / _735);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _527 = dot(d, right);\n    float _531 = dot(d, up);\n    float _542;\n    if (((_527 * _527) + (_531 * _531)) > 1.0000000133514319600180897396058e-10)\n    {\n        _542 = atan(_531, _527) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _542 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_542 - floor(_542)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _378 = abs(d);\n    float _380 = _378.x;\n    float _382 = _378.y;\n    bool _383 = _380 >= _382;\n    bool _391;\n    if (_383)\n    {\n        _391 = _380 >= _378.z;\n    }\n    else\n    {\n        _391 = _383;\n    }\n    int _392;\n    if (_391)\n    {\n        _392 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _406;\n        if (_382 >= _378.z)\n        {\n            _406 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _406 = (d.z > 0.0) ? 4 : 5;\n        }\n        _392 = _406;\n    }\n    return _392;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _773 = fa_light_base(param);\n    bool _777 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _773;\n    vec4 _781 = fa_light_texel(param_1);\n    int param_2 = _773 + 1;\n    vec4 _786 = fa_light_texel(param_2);\n    float _789 = _786.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _801 = _777 && (_789 > 2.5);\n    fa_light_is_area = _801;\n    bool _803 = _789 < 0.5;\n    vec3 l;\n    if (_803)\n    {\n        l = normalize(_781.xyz);\n        if (_777)\n        {\n            int param_3 = _773 + 6;\n            vec4 _817 = fa_light_texel(param_3);\n            if (_817.z > 0.5)\n            {\n                int param_4 = _773 + 4;\n                vec4 _827 = fa_light_texel(param_4);\n                int param_5 = _773 + 5;\n                vec4 _832 = fa_light_texel(param_5);\n                vec2 param_6 = _817.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _827.xyz) * _827.w, (-dot(world_pos, _832.xyz)) * _832.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _862 = _781.xyz;\n        vec3 _864 = _862 - world_pos;\n        vec3 to_light = _864;\n        float _867 = length(_864);\n        float reach = _867;\n        bool front = true;\n        if (_801)\n        {\n            int param_8 = _773 + 7;\n            reach = max(_867 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _773 + 4;\n            vec4 _891 = fa_light_texel(param_9);\n            int param_10 = _773 + 5;\n            vec4 _896 = fa_light_texel(param_10);\n            int param_11 = _773 + 6;\n            vec4 _901 = fa_light_texel(param_11);\n            float _902 = _901.w;\n            int param_12 = _773 + 2;\n            vec3 _909 = normalize(fa_light_texel(param_12).xyz);\n            bool _911 = _902 > 1.5;\n            bool _919;\n            if (!_911)\n            {\n                _919 = dot(_909, to_light) < 0.0;\n            }\n            else\n            {\n                _919 = _911;\n            }\n            front = _919;\n            vec3 r = vec3(0.0);\n            vec3 _928 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _932 = dot(n, n) > 0.5;\n            bool _940;\n            if (_932)\n            {\n                _940 = dot(_928, _928) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _940 = _932;\n            }\n            if (_940)\n            {\n                r = reflect(-normalize(_928), normalize(n));\n            }\n            vec3 param_13 = _862;\n            vec3 param_14 = _909;\n            vec3 param_15 = _891.xyz;\n            vec3 param_16 = _896.xyz;\n            float param_17 = _891.w;\n            float param_18 = _896.w;\n            float param_19 = _902;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _976 = length(to_light);\n        dist = _976;\n        l = to_light / vec3(max(_976, 9.9999997473787516355514526367188e-05));\n        float _990 = reach / max(_781.w, 0.001000000047497451305389404296875);\n        float _996 = clamp(1.0 - (_990 * _990), 0.0, 1.0);\n        float _998;\n        if (front)\n        {\n            _998 = _996 * _996;\n        }\n        else\n        {\n            _998 = 0.0;\n        }\n        atten = _998;\n        bool _1009 = _789 < 2.5;\n        if ((_789 > 1.5) && _1009)\n        {\n            int param_22 = _773 + 2;\n            vec4 _1017 = fa_light_texel(param_22);\n            float _1027 = _1017.w;\n            int param_23 = _773 + 3;\n            vec4 _1032 = fa_light_texel(param_23);\n            float _1033 = _1032.x;\n            float cos_inner = _1033;\n            if (_1033 > 1.5)\n            {\n                cos_inner = mix(_1027, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1027, cos_inner, dot(-l, normalize(_1017.xyz)));\n        }\n        if (_777 && (_789 < 1.5))\n        {\n            int param_24 = _773 + 6;\n            vec4 _1057 = fa_light_texel(param_24);\n            if (_1057.z > 0.5)\n            {\n                vec3 _1065 = -to_light;\n                int param_25 = _773 + 4;\n                int param_26 = _773 + 5;\n                vec3 _1079 = fa_light_texel(param_25).xyz;\n                vec3 _1083 = fa_light_texel(param_26).xyz;\n                vec3 _1092 = vec3(dot(_1065, _1079), dot(_1065, _1083), dot(_1065, cross(_1079, _1083)));\n                vec3 param_27 = _1092;\n                int _1096 = fa_cube_face(param_27);\n                int param_28 = _1096;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1123 = vec2(dot(_1092, cross(param_29, param_30)), dot(_1092, param_30)) / vec2(max(dot(_1092, param_29), 9.9999997473787516355514526367188e-05));\n                int _1127 = _1096 / 3;\n                vec2 param_31 = _1057.xy + (vec2(float(_1096 - (_1127 * 3)), float(_1127)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1123.x), 0.5 - (0.5 * _1123.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _773 + 7;\n            vec4 _1157 = fa_light_texel(param_33);\n            if (_1157.z > 0.5)\n            {\n                int param_34 = _773 + 2;\n                int param_35 = _773 + 4;\n                int param_36 = _773 + 5;\n                vec2 param_37 = _1157.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_777 && _1009)\n            {\n                int param_42 = _773 + 6;\n                vec4 _1204 = fa_light_texel(param_42);\n                int param_43 = _773 + 7;\n                vec4 _1209 = fa_light_texel(param_43);\n                bool _1212 = _1204.z > 0.5;\n                bool _1219;\n                if (!_1212)\n                {\n                    _1219 = _1209.z > 0.5;\n                }\n                else\n                {\n                    _1219 = _1212;\n                }\n                if (_1219)\n                {\n                    int param_44 = _773 + 2;\n                    vec4 _1226 = fa_light_texel(param_44);\n                    vec3 _1230 = normalize(_1226.xyz);\n                    int param_45 = _773 + 4;\n                    vec4 _1235 = fa_light_texel(param_45);\n                    int param_46 = _773 + 5;\n                    vec4 _1240 = fa_light_texel(param_46);\n                    if (_1212)\n                    {\n                        vec3 _1248 = -to_light;\n                        float _1255 = _1226.w;\n                        float _1271 = 0.5 / max(dot(_1248, _1230) * (sqrt(max(1.0 - (_1255 * _1255), 0.0)) / max(_1255, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1204.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1248, _1235.xyz) * _1271), 0.5 - (dot(_1248, _1240.xyz) * _1271));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1209.z > 0.5)\n                    {\n                        vec2 param_49 = _1209.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1230;\n                        vec3 param_52 = _1235.xyz;\n                        vec3 param_53 = _1240.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6160 = _786.xyz * atten;\n    if (_777)\n    {\n        _6160 *= fa_light_tint;\n    }\n    int _1339;\n    if (_803)\n    {\n        _1339 = 0;\n    }\n    else\n    {\n        _1339 = ((_789 > 1.5) && (_789 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6160, atten, 1.0, dist, _1339);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2128 = fa_shadow_depth(param, param_1);\n    float _2132;\n    if (conv.x < 0.5)\n    {\n        _2132 = _2128;\n    }\n    else\n    {\n        _2132 = (conv.y * conv.z) / (conv.z - (_2128 * (conv.z - conv.y)));\n    }\n    return _2132;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2178 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2184 = vec2(cos(_2178), sin(_2178));\n    vec2 dir = _2184;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2193;\n        if (k < 0.0)\n        {\n            _2193 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2193 = k;\n        }\n        float _2212 = clamp((_2193 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2231 = sqrt((float(i) + 0.5) * 0.0625) * _2212;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2231));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2245 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2245 < (zr - (_2231 * plane)))\n            {\n                sum += _2245;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2273 = sum / cnt;\n        float _2283;\n        if (k < 0.0)\n        {\n            _2283 = (-k) / max(_2273, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2283 = k;\n        }\n        radius = clamp(((max(zr - _2273, 0.0) * unit) * _2283) / texel_m, 1.5, 16.0);\n        dir = _2184;\n    }\n    float lit = 0.0;\n    int _2309 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2309; i_1++)\n    {\n        float _2328 = sqrt((float(i_1) + 0.5) / float(_2309)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2328));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2328 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2309);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2533 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2540;\n    if (!_2533)\n    {\n        _2540 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2540 = _2533;\n    }\n    if (_2540)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2553 = fa_light_texel(param);\n    float _2554 = _2553.x;\n    if (_2554 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2563 = int(_2554 + 0.5);\n    int param_1 = _2563;\n    vec4 _2567 = fa_light_texel(param_1);\n    int param_2 = _2563 + 1;\n    vec4 _2572 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2575 = _2567.y;\n    if (_2575 > 0.0)\n    {\n        float _2592 = 1.0 - smoothstep(0.75 * _2575, _2575, length(world - fa_shadows[27].xyz));\n        fade = _2592;\n        if (_2592 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2567.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2616 = (_2563 + 2) + (face * 6);\n    int param_4 = _2616;\n    int param_5 = _2616 + 1;\n    int param_6 = _2616 + 3;\n    vec4 _2630 = fa_light_texel(param_6);\n    int param_7 = _2616 + 4;\n    vec4 _2635 = fa_light_texel(param_7);\n    int param_8 = _2616 + 5;\n    vec4 _2640 = fa_light_texel(param_8);\n    float _2652 = _2640.x * max(dot(_2630, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2657 = clamp(dot(n, l), 0.0, 1.0);\n    float _2680 = clamp(dot(n, _2630.xyz), -1.0, 1.0);\n    float _2699 = min(sqrt(1.0 - (_2680 * _2680)) / max(abs(dot(n, world - lpos)) / max(dot(_2630, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2702 = _2572.y;\n    float _2704;\n    if (_2702 > 0.0)\n    {\n        _2704 = _2702;\n    }\n    else\n    {\n        _2704 = 1.5 * _2652;\n    }\n    vec4 _2724 = vec4(world + (n * (_2704 * sqrt(1.0 - (_2657 * _2657)))), 1.0);\n    float _2728 = dot(_2630, _2724);\n    float _2731 = _2640.y;\n    if (_2728 < _2731)\n    {\n        return 1.0;\n    }\n    vec2 _2746 = vec2(dot(fa_light_texel(param_4), _2724), dot(fa_light_texel(param_5), _2724)) / vec2(_2728);\n    float _2748 = _2746.x;\n    bool _2751 = _2748 < _2635.x;\n    bool _2760;\n    if (!_2751)\n    {\n        _2760 = _2748 > _2635.z;\n    }\n    else\n    {\n        _2760 = _2751;\n    }\n    bool _2769;\n    if (!_2760)\n    {\n        _2769 = _2746.y < _2635.y;\n    }\n    else\n    {\n        _2769 = _2760;\n    }\n    bool _2778;\n    if (!_2769)\n    {\n        _2778 = _2746.y > _2635.w;\n    }\n    else\n    {\n        _2778 = _2769;\n    }\n    if (_2778)\n    {\n        return 1.0;\n    }\n    float _2784 = _2572.x;\n    float _2786;\n    if (_2784 > 0.0)\n    {\n        _2786 = _2784;\n    }\n    else\n    {\n        _2786 = 1.5 * _2652;\n    }\n    vec2 param_9 = _2746;\n    vec4 param_10 = _2635;\n    float param_11 = _2728 - (_2786 * (1.0 + (0.5 * _2699)));\n    float param_12 = _2652;\n    float param_13 = 1.0;\n    float param_14 = _2640.z * 0.25;\n    float param_15 = (_2652 * min(_2699, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2731, _2640.z);\n    int param_17 = int(_2567.z + 0.5);\n    float param_18 = _2567.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3293 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3299;\n    if (_3293)\n    {\n        _3299 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3299 = _3293;\n    }\n    bool _3305;\n    if (_3299)\n    {\n        _3305 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3305 = _3299;\n    }\n    if (_3305)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3317 = fa_light_texel(param);\n        float _3318 = _3317.z;\n        if (_3318 > 0.5)\n        {\n            float _3331 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3337 = ((0.00200000009499490261077880859375 * _3331) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3343 = vec4(world, 1.0);\n            float _3348 = dot(fa_mesh_fs_params[28], _3343);\n            if (_3348 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3365 = vec2(dot(fa_mesh_fs_params[26], _3343), dot(fa_mesh_fs_params[27], _3343)) / vec2(_3348);\n                float _3370 = (_3365.x * 0.5) + 0.5;\n                float _3374;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3374 = (_3365.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3374 = 0.5 - (_3365.y * 0.5);\n                }\n                bool _3390 = _3370 >= 0.0;\n                bool _3396;\n                if (_3390)\n                {\n                    _3396 = _3370 < 1.0;\n                }\n                else\n                {\n                    _3396 = _3390;\n                }\n                bool _3402;\n                if (_3396)\n                {\n                    _3402 = _3374 >= 0.0;\n                }\n                else\n                {\n                    _3402 = _3396;\n                }\n                bool _3408;\n                if (_3402)\n                {\n                    _3408 = _3374 < 1.0;\n                }\n                else\n                {\n                    _3408 = _3402;\n                }\n                if (_3408)\n                {\n                    ivec2 _3425 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3426 = clamp(ivec2(vec2(_3370, _3374) * fa_mesh_fs_params[24].zw), ivec2(0), _3425);\n                    float _3430;\n                    if (_3318 < 1.5)\n                    {\n                        _3430 = 1.0;\n                    }\n                    else\n                    {\n                        _3430 = (_3318 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    int _3452;\n                    int _3458;\n                    for (int k = 0; k < 9; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3452 = 4;\n                        }\n                        else\n                        {\n                            if (k <= 4)\n                            {\n                                _3458 = k - 1;\n                            }\n                            else\n                            {\n                                _3458 = k;\n                            }\n                            _3452 = _3458;\n                        }\n                        vec4 _3487 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3426 + ivec2((_3452 % 3) - 1, (_3452 / 3) - 1), ivec2(0), _3425), 0);\n                        bool _3490 = _3487.w > 0.5;\n                        bool _3500;\n                        if (_3490)\n                        {\n                            _3500 = abs(_3331 - _3487.x) <= _3337;\n                        }\n                        else\n                        {\n                            _3500 = _3490;\n                        }\n                        if (_3500)\n                        {\n                            best = min(best, mod(floor(_3487.z / _3430), 256.0) * 0.0039215688593685626983642578125);\n                            if (k == 0)\n                            {\n                                break;\n                            }\n                        }\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3527;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_1 = li;\n                            vec3 param_2 = lpos;\n                            vec3 param_3 = world;\n                            vec3 param_4 = n;\n                            vec3 param_5 = l;\n                            _3527 = min(best, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                        }\n                        else\n                        {\n                            _3527 = best;\n                        }\n                        return _3527;\n                    }\n                }\n            }\n            float _3550;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3550 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3550 = 1.0;\n            }\n            return _3550;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2071;\n    if (i == 0)\n    {\n        _2071 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2087;\n        if (i == 1)\n        {\n            _2087 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2095;\n            if (i == 2)\n            {\n                _2095 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2095 = fa_shadows[24].w;\n            }\n            _2087 = _2095;\n        }\n        _2071 = _2087;\n    }\n    return _2071;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2374 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2379 = clamp(dot(n, l), 0.0, 1.0);\n    float _2385 = sqrt(1.0 - (_2379 * _2379));\n    float _2393 = min(_2385 / max(_2379, 0.20000000298023223876953125), 4.0);\n    float _2398;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2398 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2398 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2423 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2398 * _2385)), 1.0);\n    float _2430 = _2423.x;\n    bool _2433 = _2430 < fa_shadows[ci * 1 + 16].x;\n    bool _2442;\n    if (!_2433)\n    {\n        _2442 = _2430 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2442 = _2433;\n    }\n    bool _2451;\n    if (!_2442)\n    {\n        _2451 = _2423.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2451 = _2442;\n    }\n    bool _2460;\n    if (!_2451)\n    {\n        _2460 = _2423.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2460 = _2451;\n    }\n    bool _2467;\n    if (!_2460)\n    {\n        _2467 = _2423.z > 1.0;\n    }\n    else\n    {\n        _2467 = _2460;\n    }\n    if (_2467)\n    {\n        return -1.0;\n    }\n    float _2475;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2475 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2475 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2423.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2423.z - ((_2475 * (1.0 + (0.5 * _2393))) / _2374);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2374;\n    float param_5 = _2374 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2393, 3.0)) * 0.5) / _2374;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2853 = int(fa_shadows[25].x + 0.5);\n    if (_2853 < 1)\n    {\n        return 1.0;\n    }\n    float _2868 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2853 - 1;\n    if (_2868 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2880 = _2853 > 1;\n    bool _2887;\n    if (_2880)\n    {\n        _2887 = _2868 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2887 = _2880;\n    }\n    if (_2887)\n    {\n        ci = 1;\n    }\n    bool _2891 = _2853 > 2;\n    bool _2898;\n    if (_2891)\n    {\n        _2898 = _2868 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2898 = _2891;\n    }\n    if (_2898)\n    {\n        ci = 2;\n    }\n    bool _2902 = _2853 > 3;\n    bool _2909;\n    if (_2902)\n    {\n        _2909 = _2868 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2909 = _2902;\n    }\n    if (_2909)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2920 = min(_2853, 4);\n    float _2961;\n    for (int c = ci; c < _2920; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2940 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2940;\n            break;\n        }\n        if (_2940 < 0.0)\n        {\n            continue;\n        }\n        s = _2940;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2961 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2961 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _2980 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2961, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2868 - (fa_shadow_split_at(param_7) - _2980)) / _2980, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3012;\n        if ((ci + 1) < _2853)\n        {\n            _3012 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3012 = 1.0;\n        }\n        s = mix(s, _3012, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3117 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3123;\n    if (_3117)\n    {\n        _3123 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3123 = _3117;\n    }\n    if (_3123)\n    {\n        float _3137 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3145 = vec4(fa_world_pos, 1.0);\n        float _3151 = dot(fa_mesh_fs_params[28], _3145);\n        if (_3151 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3170 = vec2(dot(fa_mesh_fs_params[26], _3145), dot(fa_mesh_fs_params[27], _3145)) / vec2(_3151);\n            float _3175 = (_3170.x * 0.5) + 0.5;\n            float _3179;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3179 = (_3170.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3179 = 0.5 - (_3170.y * 0.5);\n            }\n            bool _3195 = _3175 >= 0.0;\n            bool _3201;\n            if (_3195)\n            {\n                _3201 = _3175 < 1.0;\n            }\n            else\n            {\n                _3201 = _3195;\n            }\n            bool _3207;\n            if (_3201)\n            {\n                _3207 = _3179 >= 0.0;\n            }\n            else\n            {\n                _3207 = _3201;\n            }\n            bool _3213;\n            if (_3207)\n            {\n                _3213 = _3179 < 1.0;\n            }\n            else\n            {\n                _3213 = _3207;\n            }\n            if (_3213)\n            {\n                vec4 _3239 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3175, _3179) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3242 = _3239.w > 0.5;\n                bool _3258;\n                if (_3242)\n                {\n                    _3258 = abs(_3137 - _3239.x) <= (((0.00200000009499490261077880859375 * _3137) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3258 = _3242;\n                }\n                if (_3258)\n                {\n                    float _3264;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3264 = min(_3239.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3264 = _3239.y;\n                    }\n                    return _3264;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3920 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3927;\n    if (!_3920)\n    {\n        _3927 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3927 = _3920;\n    }\n    if (_3927)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3940 = fa_light_texel(param);\n    float _3941 = _3940.y;\n    float len = _3941;\n    if (_3941 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3953 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3962 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3953);\n    if (_3962 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3968 = len;\n    float _3971 = min(_3968, 0.89999997615814208984375 * dist);\n    len = _3971;\n    float _3977 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3953);\n    float _3982 = _3977 + (0.5 * _3971);\n    vec3 _3988 = world + (gn * _3977);\n    float _3990 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4052;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4006 = (float(k) + _3990) * 0.083333335816860198974609375;\n        vec3 _4014 = _3988 + (l * (_4006 * len));\n        vec4 _4020 = vec4(_4014, 1.0);\n        float _4025 = dot(fa_mesh_fs_params[28], _4020);\n        if (_4025 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4043 = vec2(dot(fa_mesh_fs_params[26], _4020), dot(fa_mesh_fs_params[27], _4020)) / vec2(_4025);\n        float _4047 = _4043.x * 0.5;\n        float _4048 = _4047 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4052 = (_4043.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4052 = 0.5 - (_4043.y * 0.5);\n        }\n        bool _4068 = _4048 < 0.0;\n        bool _4075;\n        if (!_4068)\n        {\n            _4075 = _4048 >= 1.0;\n        }\n        else\n        {\n            _4075 = _4068;\n        }\n        bool _4082;\n        if (!_4075)\n        {\n            _4082 = _4052 < 0.0;\n        }\n        else\n        {\n            _4082 = _4075;\n        }\n        bool _4089;\n        if (!_4082)\n        {\n            _4089 = _4052 >= 1.0;\n        }\n        else\n        {\n            _4089 = _4082;\n        }\n        if (_4089)\n        {\n            break;\n        }\n        vec4 _4113 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4048, _4052) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4113.w < 0.5)\n        {\n            continue;\n        }\n        float _4131 = (dot(fa_mesh_fs_params[29].xyz, _4014) + fa_mesh_fs_params[29].w) - _4113.x;\n        if ((_4131 > _3977) && (_4131 < _3982))\n        {\n            occ = max(occ, (1.0 - (_4006 * _4006)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4048, 0.5 - _4047), min(_4052, 1.0 - _4052))));\n        }\n    }\n    return 1.0 - (occ * _3962);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4263 = fa_baked_keep(param);\n    if (_4263 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4289 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6186 = _4289.color;\n    float _6187 = _4289.attenuation;\n    float _6188 = _4289.shadow;\n    bool _4292 = _4289.type == 0;\n    if (_4292 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4289.direction;\n        float _4303 = fa_shadow_factor(param_5, param_6);\n        _6188 = _4303;\n        _6186 *= _4303;\n    }\n    else\n    {\n        bool _4314 = _4289.type != 0;\n        bool _4320;\n        if (_4314)\n        {\n            _4320 = _6187 > 0.0;\n        }\n        else\n        {\n            _4320 = _4314;\n        }\n        if (_4320)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4289.direction;\n            float _4339 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6188 = _4339;\n            _6186 *= _4339;\n        }\n    }\n    bool _4349 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4355;\n    if (_4349)\n    {\n        _4355 = _6187 > 0.0;\n    }\n    else\n    {\n        _4355 = _4349;\n    }\n    if (_4355)\n    {\n        float _4362;\n        if (_4292)\n        {\n            _4362 = 1000000000.0;\n        }\n        else\n        {\n            _4362 = _4289._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4289.direction;\n        float param_18 = _4362;\n        float _4380 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6188 *= _4380;\n        _6186 *= _4380;\n    }\n    float _4393 = _6187;\n    float _4394 = _4393 * _4263;\n    _6187 = _4394;\n    vec3 _4398 = _6186;\n    vec3 _4399 = _4398 * _4263;\n    _6186 = _4399;\n    return LightSample(_4289.direction, _4399, _4394, _6188, _4289._distance, _4289.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3040 = int(fa_shadows[25].x + 0.5);\n    float _3050 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3055 = _3040 > 0;\n    bool _3064;\n    if (_3055)\n    {\n        int param = _3040 - 1;\n        _3064 = _3050 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3064 = _3055;\n    }\n    if (_3064)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3070 = _3040 > 1;\n        bool _3077;\n        if (_3070)\n        {\n            _3077 = _3050 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3077 = _3070;\n        }\n        if (_3077)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3083 = _3040 > 2;\n        bool _3090;\n        if (_3083)\n        {\n            _3090 = _3050 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3090 = _3083;\n        }\n        if (_3090)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3096 = _3040 > 3;\n        bool _3103;\n        if (_3096)\n        {\n            _3103 = _3050 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3103 = _3096;\n        }\n        if (_3103)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _5978 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5978 = -_5978;\n    }\n    vec3 _5552 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5978, fa_world_tangent, fa_uv, fa_vertex_color, _5552, gl_FrontFacing);\n    Surface _5560 = fa_standard_surface(param_1);\n    vec3 _6017 = _5560.albedo;\n    float _6018 = _5560.alpha;\n    vec3 _6019 = _5560.normal;\n    float _6020 = _5560.metallic;\n    float _6021 = _5560.roughness;\n    float _6022 = _5560.occlusion;\n    vec3 _6023 = _5560.emission;\n    float _6024 = _5560.clearcoat;\n    float _6025 = _5560.clearcoat_roughness;\n    vec3 _6026 = _5560.sheen_color;\n    float _6027 = _5560.sheen_roughness;\n    float _6028 = _5560.anisotropy;\n    float _6029 = _5560.anisotropy_rotation;\n    float _6030 = _5560.specular;\n    float _6031 = _5560.ior;\n    vec3 _6032 = _5560.specular_color;\n    float _6033 = _5560.transmission;\n    float _6034 = _5560.thickness;\n    vec3 _6035 = _5560.attenuation_color;\n    float _6036 = _5560.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5978, fa_world_tangent, fa_uv, fa_vertex_color, _5552, gl_FrontFacing);\n    Surface param_3 = _5560;\n    surface(param_2, param_3);\n    _6017 = param_3.albedo;\n    _6018 = param_3.alpha;\n    _6019 = param_3.normal;\n    _6020 = param_3.metallic;\n    _6021 = param_3.roughness;\n    _6022 = param_3.occlusion;\n    _6023 = param_3.emission;\n    _6024 = param_3.clearcoat;\n    _6025 = param_3.clearcoat_roughness;\n    _6026 = param_3.sheen_color;\n    _6027 = param_3.sheen_roughness;\n    _6028 = param_3.anisotropy;\n    _6029 = param_3.anisotropy_rotation;\n    _6030 = param_3.specular;\n    _6031 = param_3.ior;\n    _6032 = param_3.specular_color;\n    _6033 = param_3.transmission;\n    _6034 = param_3.thickness;\n    _6035 = param_3.attenuation_color;\n    _6036 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5978;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6017 = param_6;\n    _6019 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6017;\n    }\n    else\n    {\n        vec3 _5599 = _6019;\n        vec3 _5600 = normalize(_5599);\n        _6019 = _5600;\n        vec3 param_8 = _5600;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _5978, fa_world_tangent, fa_uv, fa_vertex_color, _5552, gl_FrontFacing);\n        Surface param_10 = Surface(_6017, _6018, _6019, _6020, _6021, _6022, _6023, _6024, _6025, _6026, _6027, _6028, _6029, _6030, _6031, _6032, _6033, _6034, _6035, _6036);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _5619 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5619; ln++)\n        {\n            int param_12 = ln;\n            int _5632 = fa_cl_light(param_12);\n            int param_13 = _5632;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _5632;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _5978;\n            LightSample _5648 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _5978, fa_world_tangent, fa_uv, fa_vertex_color, _5552, gl_FrontFacing);\n            Surface param_18 = Surface(_6017, _6018, _6019, _6020, _6021, _6022, _6023, _6024, _6025, _6026, _6027, _6028, _6029, _6030, _6031, _6032, _6033, _6034, _6035, _6036);\n            LightSample param_19 = _5648;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _5663 = result;\n    vec3 _5664 = _5663 + _6023;\n    result = _5664;\n    vec3 param_20 = _5664;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5673 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5680;\n    if (!_5673)\n    {\n        _5680 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5680 = _5673;\n    }\n    if (_5680)\n    {\n        vec3 _5689 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5695 = dot(_5689, fa_mesh_fs_params[9].xyz);\n        bool _5699 = fa_mesh_fs_params[9].w > 0.5;\n        float _5700;\n        if (_5699)\n        {\n            _5700 = _5695;\n        }\n        else\n        {\n            _5700 = length(_5689);\n        }\n        float _5712 = _5700 - fa_mesh_fs_params[8].x;\n        if (_5712 > 0.0)\n        {\n            float _5721 = fa_mesh_fs_params[7].w * _5712;\n            float tau = _5721 * _5721;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5737;\n                if (_5699)\n                {\n                    _5737 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5695);\n                }\n                else\n                {\n                    _5737 = fa_mesh_fs_params[0].y;\n                }\n                float _5758 = mix(_5737, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5700, 0.0, 1.0));\n                float _5762 = fa_world_pos.y - _5758;\n                float _5767 = _5758 - fa_mesh_fs_params[8].z;\n                float _5772 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5775 = _5767 <= 0.0;\n                bool _5776 = !_5775;\n                bool _5782;\n                if (_5776)\n                {\n                    _5782 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5782 = _5775;\n                }\n                float _5783;\n                if (_5782)\n                {\n                    _5783 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5783 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5767, 80.0));\n                }\n                bool _5810;\n                if (_5776)\n                {\n                    _5810 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5810 = _5775;\n                }\n                float _5811;\n                if (_5810)\n                {\n                    _5811 = fa_mesh_fs_params[8].y * _5767;\n                }\n                else\n                {\n                    _5811 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5767, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5836 = _5772 <= 0.0;\n                bool _5843;\n                if (!_5836)\n                {\n                    _5843 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5843 = _5836;\n                }\n                float _5844;\n                if (_5843)\n                {\n                    _5844 = fa_mesh_fs_params[8].y * _5772;\n                }\n                else\n                {\n                    _5844 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5772, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5871;\n                if (abs(_5762) < 0.001000000047497451305389404296875)\n                {\n                    _5871 = _5783;\n                }\n                else\n                {\n                    _5871 = (_5844 - _5811) / _5762;\n                }\n                tau += (_5712 * max(_5871, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6018);\n}\n\n",
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
            "inst_name": "_429",
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
            "inst_name": "_2081",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1357 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1364;\n    if (!_1357)\n    {\n        _1364 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1364 = _1357;\n    }\n    bool _1372;\n    if (!_1364)\n    {\n        _1372 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1372 = _1364;\n    }\n    bool _1379;\n    if (!_1372)\n    {\n        _1379 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1379 = _1372;\n    }\n    bool _1386;\n    if (!_1379)\n    {\n        _1386 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1386 = _1379;\n    }\n    if (_1386)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1396 = vec4(world_pos, 1.0);\n    float _1402 = dot(fa_mesh_fs_params[16], _1396);\n    if (!(_1402 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1424 = vec2(dot(fa_mesh_fs_params[14], _1396), dot(fa_mesh_fs_params[15], _1396)) / vec2(_1402);\n    int _1428 = int(fa_mesh_fs_params[18].x);\n    int _1432 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1432) + clamp(int(floor(((_1424.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1432 - 1)) * _1428)) + clamp(int(floor(((_1424.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1428 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1508 = fa_cluster_texel(param);\n    return ivec2(int(_1508.x), int(_1508.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _4208 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _4211 = fwidth(_4208);\n    bool _4214 = fa_mesh_fs_params[25].y > 0.5;\n    bool _4221;\n    if (!_4214)\n    {\n        _4221 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _4221 = _4214;\n    }\n    if (_4221)\n    {\n        fa_rt_slope = min(1.5 * _4211, 0.100000001490116119384765625 * _4208);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4237 = fa_cluster_lookup(param);\n    fa_cl_slot = _4237.x;\n    fa_cl_local = _4237.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4445 = fa_linear_to_srgb(param);\n        c = _4445;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4453 = fa_srgb_to_linear(param_1);\n            c = _4453;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _312;\n    if (i.front_facing)\n    {\n        _312 = i.world_normal;\n    }\n    else\n    {\n        _312 = -i.world_normal;\n    }\n    vec3 _336 = normalize(i.world_tangent.xyz - (_312 * dot(_312, i.world_tangent.xyz)));\n    vec3 _363 = normalize(((_336 * m.x) + ((cross(_312, _336) * i.world_tangent.w) * m.y)) + (_312 * m.z));\n    vec3 _366;\n    if (i.front_facing)\n    {\n        _366 = _363;\n    }\n    else\n    {\n        _366 = -_363;\n    }\n    return _366;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4485 = fa_tex_fix(param_2, param_3);\n    vec4 _6390 = base_t;\n    _6390.x = _4485.x;\n    _6390.y = _4485.y;\n    _6390.z = _4485.z;\n    base_t = _6390;\n    vec4 _4499 = (_6390 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6206 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4533 = fa_tex_fix(param_6, param_7);\n        vec3 _4536 = (_4533 * 2.0) - vec3(1.0);\n        vec2 _4541 = _4536.xy * fa_mesh_fs_params[6].x;\n        vec3 _6398 = _4536;\n        _6398.x = _4541.x;\n        _6398.y = _4541.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6398;\n        _6206 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4571 = fa_tex_fix(param_12, param_13);\n    vec4 _6401 = mrt;\n    _6401.x = _4571.x;\n    _6401.y = _4571.y;\n    _6401.z = _4571.z;\n    mrt = _6401;\n    vec4 _4601 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4601.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4612 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4644 = fa_tex_fix(param_20, param_21);\n    float _6211 = fa_mesh_fs_params[20].x;\n    float _6212 = fa_mesh_fs_params[20].y;\n    float _6215 = fa_mesh_fs_params[20].z;\n    float _6214 = fa_mesh_fs_params[21].w;\n    float _6217 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6211 *= _4612.y;\n            _6212 *= _4612.z;\n            _6214 *= _4601.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6215 *= mrt.x;\n            _6217 *= mrt.w;\n        }\n    }\n    return Surface(_4499.xyz, _4499.w, _6206, clamp(fa_mesh_fs_params[5].x * _4571.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4571.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4612.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4644), _6211, _6212, fa_mesh_fs_params[21].xyz, _6214, _6215, fa_mesh_fs_params[20].w, _6217, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1588 = rect.zw - rect.xy;\n    vec2 _1592 = _1588 * atlas;\n    vec2 _1596 = ddx * _1592;\n    vec2 _1600 = ddy * _1592;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1588), clamp(0.5 * log2(max(max(dot(_1596, _1596), dot(_1600, _1600)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1633 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1640;\n    if (!_1633)\n    {\n        _1640 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1640 = _1633;\n    }\n    if (_1640)\n    {\n        return;\n    }\n    vec3 _1646 = dFdx(world_pos);\n    vec3 _1649 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1653 = fa_cluster_texel(param);\n    int _1657 = int(_1653.w);\n    if (_1657 < 1)\n    {\n        return;\n    }\n    int _1667 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1667;\n    vec4 _1671 = fa_light_texel(param_1);\n    vec2 _1674 = _1671.yz;\n    int _1678 = int(_1671.w);\n    int param_2 = _1667 + 1;\n    vec4 _1683 = fa_light_texel(param_2);\n    float _1684 = _1683.x;\n    int _1690 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1694 = int(_1653.z);\n    vec3 _1959;\n    for (int k = 0; k < _1657; k++)\n    {\n        int _1707 = _1694 + k;\n        int param_3 = _1678 + (_1707 >> 2);\n        int _1724 = (_1667 + 2) + (int(fa_light_texel(param_3)[_1707 & 3]) * 7);\n        int param_4 = _1724 + 6;\n        vec4 _1729 = fa_light_texel(param_4);\n        if (((int(_1729.w + 0.5) >> _1690) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1724;\n        vec4 _1744 = fa_light_texel(param_5);\n        int param_6 = _1724 + 1;\n        vec4 _1749 = fa_light_texel(param_6);\n        int param_7 = _1724 + 2;\n        vec4 _1754 = fa_light_texel(param_7);\n        vec3 _1757 = _1744.xyz;\n        float _1762 = dot(_1757, world_pos) + _1744.w;\n        vec3 _1764 = _1749.xyz;\n        float _1769 = dot(_1764, world_pos) + _1749.w;\n        vec3 _1771 = _1754.xyz;\n        float _1776 = dot(_1771, world_pos) + _1754.w;\n        bool _1781 = abs(_1762) > 0.5;\n        bool _1789;\n        if (!_1781)\n        {\n            _1789 = abs(_1769) > 0.5;\n        }\n        else\n        {\n            _1789 = _1781;\n        }\n        bool _1797;\n        if (!_1789)\n        {\n            _1797 = abs(_1776) > 0.5;\n        }\n        else\n        {\n            _1797 = _1789;\n        }\n        if (_1797)\n        {\n            continue;\n        }\n        float _1812 = clamp(dot(geo_normal, normalize(_1771)) * _1729.z, 0.0, 1.0);\n        if (_1812 <= 0.0)\n        {\n            continue;\n        }\n        float _1832 = (clamp((0.5 - abs(_1776)) * 10.0, 0.0, 1.0) * _1812) * _1729.x;\n        vec2 _1840 = vec2(_1762 + 0.5, 0.5 - _1769);\n        vec2 _1850 = vec2(dot(_1757, _1646), dot(_1764, _1646));\n        vec2 _1860 = vec2(dot(_1757, _1649), dot(_1764, _1649));\n        int param_8 = _1724 + 5;\n        vec4 _1865 = fa_light_texel(param_8);\n        int param_9 = _1724 + 3;\n        vec4 _1870 = fa_light_texel(param_9);\n        int param_10 = _1724 + 4;\n        vec4 _1875 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1865.xyz;\n        bool _1885 = _1870.z > _1870.x;\n        if (_1885)\n        {\n            vec4 param_11 = _1870;\n            vec2 param_12 = _1840;\n            vec2 param_13 = _1674;\n            vec2 param_14 = _1850;\n            vec2 param_15 = _1860;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1684 > 0.5) && (_1684 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1911 = fa_dc_to_linear(param_16);\n                vec4 _6294 = tx;\n                _6294.x = _1911.x;\n                _6294.y = _1911.y;\n                _6294.z = _1911.z;\n                tx = _6294;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1832 * tex_a) * _1865.w, 0.0, 1.0)));\n        if (_1875.z > _1875.x)\n        {\n            vec4 param_17 = _1875;\n            vec2 param_18 = _1840;\n            vec2 param_19 = _1674;\n            vec2 param_20 = _1850;\n            vec2 param_21 = _1860;\n            vec4 _1955 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1684 > 1.5)\n            {\n                vec3 param_22 = _1955.xyz;\n                vec3 _1965 = fa_dc_to_srgb(param_22);\n                _1959 = _1965;\n            }\n            else\n            {\n                _1959 = _1955.xyz;\n            }\n            vec3 _1974 = (_1959 * 2.0) - vec3(1.0);\n            vec2 _1979 = _1974.xy * _1729.y;\n            vec3 _2001 = (normalize(_1757) * _1979.x) + (normalize(_1764) * _1979.y);\n            vec3 _2004 = normalize(normal);\n            normal = normalize(mix(_2004, normalize((_2004 * max(_1974.z, 0.0500000007450580596923828125)) + (_2001 - (_2004 * dot(_2004, _2001)))), vec3(clamp(_1832 * (_1885 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3672 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3672;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3781 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3787 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3781 > 0.0005000000237487256526947021484375)\n    {\n        if (_3787)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3781;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3781;\n        }\n    }\n    bool _3838 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3838)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3869 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3869)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3787 || _3838) || _3869)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3692 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3695 = _3692.x;\n    float _3697 = _3692.z;\n    vec2 e = vec2(_3695, _3697);\n    if (_3692.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3697)) * ((_3695 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3695)) * ((_3697 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _4758 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _4763 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _4768 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _4773 = fa_light_texel(param_3);\n    bool _4776 = _4773.z < 0.5;\n    bool _4784;\n    if (!_4776)\n    {\n        _4784 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _4784 = _4776;\n    }\n    if (_4784)\n    {\n        return vec3(0.0);\n    }\n    float _4791 = max(_4758.w, 9.9999997473787516355514526367188e-05);\n    vec3 _4794 = _4763.xyz;\n    vec3 _4798 = _4758.xyz;\n    vec3 _4802 = (fa_world_pos - _4798) / vec3(_4791);\n    vec3 _4811 = min(_4802 + vec3(0.5), (_4794 - vec3(0.5)) - _4802);\n    float _4820 = min(_4811.x, min(_4811.y, _4811.z));\n    if (!(_4820 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4835 = _4794 - vec3(1.0);\n    vec3 _4836 = clamp(_4802, vec3(0.0), _4835);\n    vec3 _4844 = min(floor(_4836), max(_4794 - vec3(2.0), vec3(0.0)));\n    vec3 _4848 = _4836 - _4844;\n    vec3 _4860 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _4791));\n    int _4865 = int(_4768.y + 0.5);\n    float _4870 = 0.3257350027561187744140625 * n.y;\n    float _4874 = 0.3257350027561187744140625 * n.z;\n    float _4878 = 0.3257350027561187744140625 * n.x;\n    float _4885 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _4892 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _4901 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _4908 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _4921 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _4928 = 8 + int(_4773.w);\n    float _4955;\n    float _4968;\n    float _4982;\n    for (int k = 0; k < _4928; k++)\n    {\n        float _4941 = float(k & 1);\n        float _4945 = float((k >> 1) & 1);\n        float _4949 = float((k >> 2) & 1);\n        if (_4941 > 0.5)\n        {\n            _4955 = _4848.x;\n        }\n        else\n        {\n            _4955 = 1.0 - _4848.x;\n        }\n        if (_4945 > 0.5)\n        {\n            _4968 = _4848.y;\n        }\n        else\n        {\n            _4968 = 1.0 - _4848.y;\n        }\n        if (_4949 > 0.5)\n        {\n            _4982 = _4848.z;\n        }\n        else\n        {\n            _4982 = 1.0 - _4848.z;\n        }\n        float _4992 = (_4955 * _4968) * _4982;\n        if (!(_4992 > 0.0))\n        {\n            continue;\n        }\n        vec3 _5005 = min(_4844 + vec3(_4941, _4945, _4949), _4835);\n        int _5025 = int(((_4768.x + _5005.x) + (_4763.x * (_5005.y + (_4763.y * _5005.z)))) + 0.5);\n        vec2 _5040 = vec2(float(_5025 % _4865) * 10.0, 1024.0 + (float(_5025 / _4865) * 11.0));\n        vec2 param_4 = _5040 + vec2(9.5, 10.5);\n        vec4 _5048 = fa_gi_fetch(param_4);\n        bool _5051 = _5048.y < 0.5;\n        bool _5060;\n        if (!_5051)\n        {\n            _5060 = _5048.x > _4773.y;\n        }\n        else\n        {\n            _5060 = _5051;\n        }\n        if (_5060)\n        {\n            continue;\n        }\n        vec3 _5072 = _4860 - (_4798 + (_5005 * _4791));\n        float _5075 = length(_5072);\n        vec3 _5081 = _5072 / vec3(max(_5075, 9.9999997473787516355514526367188e-05));\n        float _5091 = max(9.9999997473787516355514526367188e-05, (dot(-_5081, n) + 1.0) * 0.5);\n        float w = _4992 * (_5091 * _5091);\n        vec3 param_5 = _5081;\n        vec2 param_6 = (_5040 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _5111 = fa_gi_fetch(param_6);\n        float _5118 = _5075 / max(_4768.z, 9.9999997473787516355514526367188e-05);\n        float _5121 = _5111.x;\n        if (_5118 > _5121)\n        {\n            float _5134 = max(_5111.y - (_5121 * _5121), 0.0);\n            float _5139 = _5118 - _5121;\n            float _5148 = _5134 / max(_5134 + (_5139 * _5139), 9.9999999600419720025001879548654e-13);\n            w *= ((_5148 * _5148) * _5148);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _5040 + vec2(0.5, 10.5);\n        vec2 param_8 = _5040 + vec2(1.5, 10.5);\n        vec2 param_9 = _5040 + vec2(2.5, 10.5);\n        vec2 param_10 = _5040 + vec2(3.5, 10.5);\n        vec2 param_11 = _5040 + vec2(4.5, 10.5);\n        vec2 param_12 = _5040 + vec2(5.5, 10.5);\n        vec2 param_13 = _5040 + vec2(6.5, 10.5);\n        vec2 param_14 = _5040 + vec2(7.5, 10.5);\n        vec2 param_15 = _5040 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _4870)) + (fa_gi_fetch(param_9).xyz * _4874)) + (fa_gi_fetch(param_10).xyz * _4878)) + (fa_gi_fetch(param_11).xyz * _4885)) + (fa_gi_fetch(param_12).xyz * _4892)) + (fa_gi_fetch(param_13).xyz * _4901)) + (fa_gi_fetch(param_14).xyz * _4908)) + (fa_gi_fetch(param_15).xyz * _4921)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_4820 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _5276;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _5276 = _4773.x;\n    }\n    else\n    {\n        _5276 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_4768.w * _5276);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _5300 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _5305 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _5310 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _5310) && (k < 8); k++)\n    {\n        int param = _5305 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _5300;\n        vec3 _5335 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5340 = param_3 * left;\n        acc += (_5335 * _5340);\n        left -= _5340;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _5369 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5369;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _5411 = vec4(fa_world_pos, 1.0);\n        vec2 _5430 = vec2(dot(fa_mesh_fs_params[26], _5411), dot(fa_mesh_fs_params[27], _5411)) / vec2(max(dot(fa_mesh_fs_params[28], _5411), 9.9999997473787516355514526367188e-05));\n        float _5439;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5439 = (_5430.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5439 = 0.5 - (_5430.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_5430.x * 0.5) + 0.5, _5439) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return ambientColor;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4178;\n    if (fa_lm.z > 0.5)\n    {\n        _4178 = 0.0;\n    }\n    else\n    {\n        _4178 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4189 = _4178 < 1.0;\n    bool _4195;\n    if (_4189)\n    {\n        int param = li;\n        _4195 = fa_light_baked(param);\n    }\n    else\n    {\n        _4195 = _4189;\n    }\n    return _4195 ? _4178 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _607 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _620 = (c - (ru * hx)) - p;\n        vec3 _626 = ru * (2.0 * hx);\n        float _632 = max(dot(_626, _626), 9.9999999392252902907785028219223e-09);\n        float _636 = dot(_620, _626);\n        float t = clamp((-_636) / _632, 0.0, 1.0);\n        if (_607)\n        {\n            float _651 = dot(r, _626);\n            float _657 = _632 - (_651 * _651);\n            if (abs(_657) > (9.9999997473787516355514526367188e-06 * _632))\n            {\n                t = clamp(((dot(r, _620) * _651) - _636) / _657, 0.0, 1.0);\n            }\n        }\n        return (p + _620) + (_626 * t);\n    }\n    vec3 q = p;\n    float _689 = dot(r, axis);\n    bool _697;\n    if (_607)\n    {\n        _697 = abs(_689) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _697 = _607;\n    }\n    if (_697)\n    {\n        float _707 = dot(c - p, axis) / _689;\n        if (_707 > 0.0)\n        {\n            q = p + (r * _707);\n        }\n    }\n    vec3 _720 = q - c;\n    vec2 xy = vec2(dot(_720, ru), dot(_720, uu));\n    if (shape > 0.5)\n    {\n        float _735 = length(xy);\n        if (_735 > hx)\n        {\n            xy *= (hx / _735);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _527 = dot(d, right);\n    float _531 = dot(d, up);\n    float _542;\n    if (((_527 * _527) + (_531 * _531)) > 1.0000000133514319600180897396058e-10)\n    {\n        _542 = atan(_531, _527) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _542 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_542 - floor(_542)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _378 = abs(d);\n    float _380 = _378.x;\n    float _382 = _378.y;\n    bool _383 = _380 >= _382;\n    bool _391;\n    if (_383)\n    {\n        _391 = _380 >= _378.z;\n    }\n    else\n    {\n        _391 = _383;\n    }\n    int _392;\n    if (_391)\n    {\n        _392 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _406;\n        if (_382 >= _378.z)\n        {\n            _406 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _406 = (d.z > 0.0) ? 4 : 5;\n        }\n        _392 = _406;\n    }\n    return _392;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _773 = fa_light_base(param);\n    bool _777 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _773;\n    vec4 _781 = fa_light_texel(param_1);\n    int param_2 = _773 + 1;\n    vec4 _786 = fa_light_texel(param_2);\n    float _789 = _786.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _801 = _777 && (_789 > 2.5);\n    fa_light_is_area = _801;\n    bool _803 = _789 < 0.5;\n    vec3 l;\n    if (_803)\n    {\n        l = normalize(_781.xyz);\n        if (_777)\n        {\n            int param_3 = _773 + 6;\n            vec4 _817 = fa_light_texel(param_3);\n            if (_817.z > 0.5)\n            {\n                int param_4 = _773 + 4;\n                vec4 _827 = fa_light_texel(param_4);\n                int param_5 = _773 + 5;\n                vec4 _832 = fa_light_texel(param_5);\n                vec2 param_6 = _817.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _827.xyz) * _827.w, (-dot(world_pos, _832.xyz)) * _832.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _862 = _781.xyz;\n        vec3 _864 = _862 - world_pos;\n        vec3 to_light = _864;\n        float _867 = length(_864);\n        float reach = _867;\n        bool front = true;\n        if (_801)\n        {\n            int param_8 = _773 + 7;\n            reach = max(_867 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _773 + 4;\n            vec4 _891 = fa_light_texel(param_9);\n            int param_10 = _773 + 5;\n            vec4 _896 = fa_light_texel(param_10);\n            int param_11 = _773 + 6;\n            vec4 _901 = fa_light_texel(param_11);\n            float _902 = _901.w;\n            int param_12 = _773 + 2;\n            vec3 _909 = normalize(fa_light_texel(param_12).xyz);\n            bool _911 = _902 > 1.5;\n            bool _919;\n            if (!_911)\n            {\n                _919 = dot(_909, to_light) < 0.0;\n            }\n            else\n            {\n                _919 = _911;\n            }\n            front = _919;\n            vec3 r = vec3(0.0);\n            vec3 _928 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _932 = dot(n, n) > 0.5;\n            bool _940;\n            if (_932)\n            {\n                _940 = dot(_928, _928) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _940 = _932;\n            }\n            if (_940)\n            {\n                r = reflect(-normalize(_928), normalize(n));\n            }\n            vec3 param_13 = _862;\n            vec3 param_14 = _909;\n            vec3 param_15 = _891.xyz;\n            vec3 param_16 = _896.xyz;\n            float param_17 = _891.w;\n            float param_18 = _896.w;\n            float param_19 = _902;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _976 = length(to_light);\n        dist = _976;\n        l = to_light / vec3(max(_976, 9.9999997473787516355514526367188e-05));\n        float _990 = reach / max(_781.w, 0.001000000047497451305389404296875);\n        float _996 = clamp(1.0 - (_990 * _990), 0.0, 1.0);\n        float _998;\n        if (front)\n        {\n            _998 = _996 * _996;\n        }\n        else\n        {\n            _998 = 0.0;\n        }\n        atten = _998;\n        bool _1009 = _789 < 2.5;\n        if ((_789 > 1.5) && _1009)\n        {\n            int param_22 = _773 + 2;\n            vec4 _1017 = fa_light_texel(param_22);\n            float _1027 = _1017.w;\n            int param_23 = _773 + 3;\n            vec4 _1032 = fa_light_texel(param_23);\n            float _1033 = _1032.x;\n            float cos_inner = _1033;\n            if (_1033 > 1.5)\n            {\n                cos_inner = mix(_1027, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1027, cos_inner, dot(-l, normalize(_1017.xyz)));\n        }\n        if (_777 && (_789 < 1.5))\n        {\n            int param_24 = _773 + 6;\n            vec4 _1057 = fa_light_texel(param_24);\n            if (_1057.z > 0.5)\n            {\n                vec3 _1065 = -to_light;\n                int param_25 = _773 + 4;\n                int param_26 = _773 + 5;\n                vec3 _1079 = fa_light_texel(param_25).xyz;\n                vec3 _1083 = fa_light_texel(param_26).xyz;\n                vec3 _1092 = vec3(dot(_1065, _1079), dot(_1065, _1083), dot(_1065, cross(_1079, _1083)));\n                vec3 param_27 = _1092;\n                int _1096 = fa_cube_face(param_27);\n                int param_28 = _1096;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1123 = vec2(dot(_1092, cross(param_29, param_30)), dot(_1092, param_30)) / vec2(max(dot(_1092, param_29), 9.9999997473787516355514526367188e-05));\n                int _1127 = _1096 / 3;\n                vec2 param_31 = _1057.xy + (vec2(float(_1096 - (_1127 * 3)), float(_1127)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1123.x), 0.5 - (0.5 * _1123.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _773 + 7;\n            vec4 _1157 = fa_light_texel(param_33);\n            if (_1157.z > 0.5)\n            {\n                int param_34 = _773 + 2;\n                int param_35 = _773 + 4;\n                int param_36 = _773 + 5;\n                vec2 param_37 = _1157.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_777 && _1009)\n            {\n                int param_42 = _773 + 6;\n                vec4 _1204 = fa_light_texel(param_42);\n                int param_43 = _773 + 7;\n                vec4 _1209 = fa_light_texel(param_43);\n                bool _1212 = _1204.z > 0.5;\n                bool _1219;\n                if (!_1212)\n                {\n                    _1219 = _1209.z > 0.5;\n                }\n                else\n                {\n                    _1219 = _1212;\n                }\n                if (_1219)\n                {\n                    int param_44 = _773 + 2;\n                    vec4 _1226 = fa_light_texel(param_44);\n                    vec3 _1230 = normalize(_1226.xyz);\n                    int param_45 = _773 + 4;\n                    vec4 _1235 = fa_light_texel(param_45);\n                    int param_46 = _773 + 5;\n                    vec4 _1240 = fa_light_texel(param_46);\n                    if (_1212)\n                    {\n                        vec3 _1248 = -to_light;\n                        float _1255 = _1226.w;\n                        float _1271 = 0.5 / max(dot(_1248, _1230) * (sqrt(max(1.0 - (_1255 * _1255), 0.0)) / max(_1255, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1204.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1248, _1235.xyz) * _1271), 0.5 - (dot(_1248, _1240.xyz) * _1271));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1209.z > 0.5)\n                    {\n                        vec2 param_49 = _1209.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1230;\n                        vec3 param_52 = _1235.xyz;\n                        vec3 param_53 = _1240.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6160 = _786.xyz * atten;\n    if (_777)\n    {\n        _6160 *= fa_light_tint;\n    }\n    int _1339;\n    if (_803)\n    {\n        _1339 = 0;\n    }\n    else\n    {\n        _1339 = ((_789 > 1.5) && (_789 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6160, atten, 1.0, dist, _1339);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2128 = fa_shadow_depth(param, param_1);\n    float _2132;\n    if (conv.x < 0.5)\n    {\n        _2132 = _2128;\n    }\n    else\n    {\n        _2132 = (conv.y * conv.z) / (conv.z - (_2128 * (conv.z - conv.y)));\n    }\n    return _2132;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2178 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2184 = vec2(cos(_2178), sin(_2178));\n    vec2 dir = _2184;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2193;\n        if (k < 0.0)\n        {\n            _2193 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2193 = k;\n        }\n        float _2212 = clamp((_2193 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2231 = sqrt((float(i) + 0.5) * 0.0625) * _2212;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2231));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2245 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2245 < (zr - (_2231 * plane)))\n            {\n                sum += _2245;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2273 = sum / cnt;\n        float _2283;\n        if (k < 0.0)\n        {\n            _2283 = (-k) / max(_2273, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2283 = k;\n        }\n        radius = clamp(((max(zr - _2273, 0.0) * unit) * _2283) / texel_m, 1.5, 16.0);\n        dir = _2184;\n    }\n    float lit = 0.0;\n    int _2309 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2309; i_1++)\n    {\n        float _2328 = sqrt((float(i_1) + 0.5) / float(_2309)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2328));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2328 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2309);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2533 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2540;\n    if (!_2533)\n    {\n        _2540 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2540 = _2533;\n    }\n    if (_2540)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2553 = fa_light_texel(param);\n    float _2554 = _2553.x;\n    if (_2554 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2563 = int(_2554 + 0.5);\n    int param_1 = _2563;\n    vec4 _2567 = fa_light_texel(param_1);\n    int param_2 = _2563 + 1;\n    vec4 _2572 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2575 = _2567.y;\n    if (_2575 > 0.0)\n    {\n        float _2592 = 1.0 - smoothstep(0.75 * _2575, _2575, length(world - fa_shadows[27].xyz));\n        fade = _2592;\n        if (_2592 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2567.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2616 = (_2563 + 2) + (face * 6);\n    int param_4 = _2616;\n    int param_5 = _2616 + 1;\n    int param_6 = _2616 + 3;\n    vec4 _2630 = fa_light_texel(param_6);\n    int param_7 = _2616 + 4;\n    vec4 _2635 = fa_light_texel(param_7);\n    int param_8 = _2616 + 5;\n    vec4 _2640 = fa_light_texel(param_8);\n    float _2652 = _2640.x * max(dot(_2630, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2657 = clamp(dot(n, l), 0.0, 1.0);\n    float _2680 = clamp(dot(n, _2630.xyz), -1.0, 1.0);\n    float _2699 = min(sqrt(1.0 - (_2680 * _2680)) / max(abs(dot(n, world - lpos)) / max(dot(_2630, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2702 = _2572.y;\n    float _2704;\n    if (_2702 > 0.0)\n    {\n        _2704 = _2702;\n    }\n    else\n    {\n        _2704 = 1.5 * _2652;\n    }\n    vec4 _2724 = vec4(world + (n * (_2704 * sqrt(1.0 - (_2657 * _2657)))), 1.0);\n    float _2728 = dot(_2630, _2724);\n    float _2731 = _2640.y;\n    if (_2728 < _2731)\n    {\n        return 1.0;\n    }\n    vec2 _2746 = vec2(dot(fa_light_texel(param_4), _2724), dot(fa_light_texel(param_5), _2724)) / vec2(_2728);\n    float _2748 = _2746.x;\n    bool _2751 = _2748 < _2635.x;\n    bool _2760;\n    if (!_2751)\n    {\n        _2760 = _2748 > _2635.z;\n    }\n    else\n    {\n        _2760 = _2751;\n    }\n    bool _2769;\n    if (!_2760)\n    {\n        _2769 = _2746.y < _2635.y;\n    }\n    else\n    {\n        _2769 = _2760;\n    }\n    bool _2778;\n    if (!_2769)\n    {\n        _2778 = _2746.y > _2635.w;\n    }\n    else\n    {\n        _2778 = _2769;\n    }\n    if (_2778)\n    {\n        return 1.0;\n    }\n    float _2784 = _2572.x;\n    float _2786;\n    if (_2784 > 0.0)\n    {\n        _2786 = _2784;\n    }\n    else\n    {\n        _2786 = 1.5 * _2652;\n    }\n    vec2 param_9 = _2746;\n    vec4 param_10 = _2635;\n    float param_11 = _2728 - (_2786 * (1.0 + (0.5 * _2699)));\n    float param_12 = _2652;\n    float param_13 = 1.0;\n    float param_14 = _2640.z * 0.25;\n    float param_15 = (_2652 * min(_2699, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2731, _2640.z);\n    int param_17 = int(_2567.z + 0.5);\n    float param_18 = _2567.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3293 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3299;\n    if (_3293)\n    {\n        _3299 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3299 = _3293;\n    }\n    bool _3305;\n    if (_3299)\n    {\n        _3305 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3305 = _3299;\n    }\n    if (_3305)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3317 = fa_light_texel(param);\n        float _3318 = _3317.z;\n        if (_3318 > 0.5)\n        {\n            float _3331 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3337 = ((0.00200000009499490261077880859375 * _3331) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3343 = vec4(world, 1.0);\n            float _3348 = dot(fa_mesh_fs_params[28], _3343);\n            if (_3348 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3365 = vec2(dot(fa_mesh_fs_params[26], _3343), dot(fa_mesh_fs_params[27], _3343)) / vec2(_3348);\n                float _3370 = (_3365.x * 0.5) + 0.5;\n                float _3374;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3374 = (_3365.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3374 = 0.5 - (_3365.y * 0.5);\n                }\n                bool _3390 = _3370 >= 0.0;\n                bool _3396;\n                if (_3390)\n                {\n                    _3396 = _3370 < 1.0;\n                }\n                else\n                {\n                    _3396 = _3390;\n                }\n                bool _3402;\n                if (_3396)\n                {\n                    _3402 = _3374 >= 0.0;\n                }\n                else\n                {\n                    _3402 = _3396;\n                }\n                bool _3408;\n                if (_3402)\n                {\n                    _3408 = _3374 < 1.0;\n                }\n                else\n                {\n                    _3408 = _3402;\n                }\n                if (_3408)\n                {\n                    ivec2 _3425 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3426 = clamp(ivec2(vec2(_3370, _3374) * fa_mesh_fs_params[24].zw), ivec2(0), _3425);\n                    float _3430;\n                    if (_3318 < 1.5)\n                    {\n                        _3430 = 1.0;\n                    }\n                    else\n                    {\n                        _3430 = (_3318 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    int _3452;\n                    int _3458;\n                    for (int k = 0; k < 9; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3452 = 4;\n                        }\n                        else\n                        {\n                            if (k <= 4)\n                            {\n                                _3458 = k - 1;\n                            }\n                            else\n                            {\n                                _3458 = k;\n                            }\n                            _3452 = _3458;\n                        }\n                        vec4 _3487 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3426 + ivec2((_3452 % 3) - 1, (_3452 / 3) - 1), ivec2(0), _3425), 0);\n                        bool _3490 = _3487.w > 0.5;\n                        bool _3500;\n                        if (_3490)\n                        {\n                            _3500 = abs(_3331 - _3487.x) <= _3337;\n                        }\n                        else\n                        {\n                            _3500 = _3490;\n                        }\n                        if (_3500)\n                        {\n                            best = min(best, mod(floor(_3487.z / _3430), 256.0) * 0.0039215688593685626983642578125);\n                            if (k == 0)\n                            {\n                                break;\n                            }\n                        }\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3527;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_1 = li;\n                            vec3 param_2 = lpos;\n                            vec3 param_3 = world;\n                            vec3 param_4 = n;\n                            vec3 param_5 = l;\n                            _3527 = min(best, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                        }\n                        else\n                        {\n                            _3527 = best;\n                        }\n                        return _3527;\n                    }\n                }\n            }\n            float _3550;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3550 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3550 = 1.0;\n            }\n            return _3550;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2071;\n    if (i == 0)\n    {\n        _2071 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2087;\n        if (i == 1)\n        {\n            _2087 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2095;\n            if (i == 2)\n            {\n                _2095 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2095 = fa_shadows[24].w;\n            }\n            _2087 = _2095;\n        }\n        _2071 = _2087;\n    }\n    return _2071;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2374 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2379 = clamp(dot(n, l), 0.0, 1.0);\n    float _2385 = sqrt(1.0 - (_2379 * _2379));\n    float _2393 = min(_2385 / max(_2379, 0.20000000298023223876953125), 4.0);\n    float _2398;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2398 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2398 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2423 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2398 * _2385)), 1.0);\n    float _2430 = _2423.x;\n    bool _2433 = _2430 < fa_shadows[ci * 1 + 16].x;\n    bool _2442;\n    if (!_2433)\n    {\n        _2442 = _2430 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2442 = _2433;\n    }\n    bool _2451;\n    if (!_2442)\n    {\n        _2451 = _2423.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2451 = _2442;\n    }\n    bool _2460;\n    if (!_2451)\n    {\n        _2460 = _2423.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2460 = _2451;\n    }\n    bool _2467;\n    if (!_2460)\n    {\n        _2467 = _2423.z > 1.0;\n    }\n    else\n    {\n        _2467 = _2460;\n    }\n    if (_2467)\n    {\n        return -1.0;\n    }\n    float _2475;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2475 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2475 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2423.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2423.z - ((_2475 * (1.0 + (0.5 * _2393))) / _2374);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2374;\n    float param_5 = _2374 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2393, 3.0)) * 0.5) / _2374;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2853 = int(fa_shadows[25].x + 0.5);\n    if (_2853 < 1)\n    {\n        return 1.0;\n    }\n    float _2868 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2853 - 1;\n    if (_2868 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2880 = _2853 > 1;\n    bool _2887;\n    if (_2880)\n    {\n        _2887 = _2868 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2887 = _2880;\n    }\n    if (_2887)\n    {\n        ci = 1;\n    }\n    bool _2891 = _2853 > 2;\n    bool _2898;\n    if (_2891)\n    {\n        _2898 = _2868 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2898 = _2891;\n    }\n    if (_2898)\n    {\n        ci = 2;\n    }\n    bool _2902 = _2853 > 3;\n    bool _2909;\n    if (_2902)\n    {\n        _2909 = _2868 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2909 = _2902;\n    }\n    if (_2909)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2920 = min(_2853, 4);\n    float _2961;\n    for (int c = ci; c < _2920; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2940 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2940;\n            break;\n        }\n        if (_2940 < 0.0)\n        {\n            continue;\n        }\n        s = _2940;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2961 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2961 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _2980 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2961, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2868 - (fa_shadow_split_at(param_7) - _2980)) / _2980, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3012;\n        if ((ci + 1) < _2853)\n        {\n            _3012 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3012 = 1.0;\n        }\n        s = mix(s, _3012, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3117 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3123;\n    if (_3117)\n    {\n        _3123 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3123 = _3117;\n    }\n    if (_3123)\n    {\n        float _3137 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3145 = vec4(fa_world_pos, 1.0);\n        float _3151 = dot(fa_mesh_fs_params[28], _3145);\n        if (_3151 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3170 = vec2(dot(fa_mesh_fs_params[26], _3145), dot(fa_mesh_fs_params[27], _3145)) / vec2(_3151);\n            float _3175 = (_3170.x * 0.5) + 0.5;\n            float _3179;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3179 = (_3170.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3179 = 0.5 - (_3170.y * 0.5);\n            }\n            bool _3195 = _3175 >= 0.0;\n            bool _3201;\n            if (_3195)\n            {\n                _3201 = _3175 < 1.0;\n            }\n            else\n            {\n                _3201 = _3195;\n            }\n            bool _3207;\n            if (_3201)\n            {\n                _3207 = _3179 >= 0.0;\n            }\n            else\n            {\n                _3207 = _3201;\n            }\n            bool _3213;\n            if (_3207)\n            {\n                _3213 = _3179 < 1.0;\n            }\n            else\n            {\n                _3213 = _3207;\n            }\n            if (_3213)\n            {\n                vec4 _3239 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3175, _3179) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3242 = _3239.w > 0.5;\n                bool _3258;\n                if (_3242)\n                {\n                    _3258 = abs(_3137 - _3239.x) <= (((0.00200000009499490261077880859375 * _3137) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3258 = _3242;\n                }\n                if (_3258)\n                {\n                    float _3264;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3264 = min(_3239.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3264 = _3239.y;\n                    }\n                    return _3264;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3920 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3927;\n    if (!_3920)\n    {\n        _3927 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3927 = _3920;\n    }\n    if (_3927)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3940 = fa_light_texel(param);\n    float _3941 = _3940.y;\n    float len = _3941;\n    if (_3941 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3953 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3962 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3953);\n    if (_3962 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3968 = len;\n    float _3971 = min(_3968, 0.89999997615814208984375 * dist);\n    len = _3971;\n    float _3977 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3953);\n    float _3982 = _3977 + (0.5 * _3971);\n    vec3 _3988 = world + (gn * _3977);\n    float _3990 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4052;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4006 = (float(k) + _3990) * 0.083333335816860198974609375;\n        vec3 _4014 = _3988 + (l * (_4006 * len));\n        vec4 _4020 = vec4(_4014, 1.0);\n        float _4025 = dot(fa_mesh_fs_params[28], _4020);\n        if (_4025 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4043 = vec2(dot(fa_mesh_fs_params[26], _4020), dot(fa_mesh_fs_params[27], _4020)) / vec2(_4025);\n        float _4047 = _4043.x * 0.5;\n        float _4048 = _4047 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4052 = (_4043.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4052 = 0.5 - (_4043.y * 0.5);\n        }\n        bool _4068 = _4048 < 0.0;\n        bool _4075;\n        if (!_4068)\n        {\n            _4075 = _4048 >= 1.0;\n        }\n        else\n        {\n            _4075 = _4068;\n        }\n        bool _4082;\n        if (!_4075)\n        {\n            _4082 = _4052 < 0.0;\n        }\n        else\n        {\n            _4082 = _4075;\n        }\n        bool _4089;\n        if (!_4082)\n        {\n            _4089 = _4052 >= 1.0;\n        }\n        else\n        {\n            _4089 = _4082;\n        }\n        if (_4089)\n        {\n            break;\n        }\n        vec4 _4113 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4048, _4052) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4113.w < 0.5)\n        {\n            continue;\n        }\n        float _4131 = (dot(fa_mesh_fs_params[29].xyz, _4014) + fa_mesh_fs_params[29].w) - _4113.x;\n        if ((_4131 > _3977) && (_4131 < _3982))\n        {\n            occ = max(occ, (1.0 - (_4006 * _4006)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4048, 0.5 - _4047), min(_4052, 1.0 - _4052))));\n        }\n    }\n    return 1.0 - (occ * _3962);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4263 = fa_baked_keep(param);\n    if (_4263 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4289 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6186 = _4289.color;\n    float _6187 = _4289.attenuation;\n    float _6188 = _4289.shadow;\n    bool _4292 = _4289.type == 0;\n    if (_4292 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4289.direction;\n        float _4303 = fa_shadow_factor(param_5, param_6);\n        _6188 = _4303;\n        _6186 *= _4303;\n    }\n    else\n    {\n        bool _4314 = _4289.type != 0;\n        bool _4320;\n        if (_4314)\n        {\n            _4320 = _6187 > 0.0;\n        }\n        else\n        {\n            _4320 = _4314;\n        }\n        if (_4320)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4289.direction;\n            float _4339 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6188 = _4339;\n            _6186 *= _4339;\n        }\n    }\n    bool _4349 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4355;\n    if (_4349)\n    {\n        _4355 = _6187 > 0.0;\n    }\n    else\n    {\n        _4355 = _4349;\n    }\n    if (_4355)\n    {\n        float _4362;\n        if (_4292)\n        {\n            _4362 = 1000000000.0;\n        }\n        else\n        {\n            _4362 = _4289._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4289.direction;\n        float param_18 = _4362;\n        float _4380 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6188 *= _4380;\n        _6186 *= _4380;\n    }\n    float _4393 = _6187;\n    float _4394 = _4393 * _4263;\n    _6187 = _4394;\n    vec3 _4398 = _6186;\n    vec3 _4399 = _4398 * _4263;\n    _6186 = _4399;\n    return LightSample(_4289.direction, _4399, _4394, _6188, _4289._distance, _4289.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3040 = int(fa_shadows[25].x + 0.5);\n    float _3050 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3055 = _3040 > 0;\n    bool _3064;\n    if (_3055)\n    {\n        int param = _3040 - 1;\n        _3064 = _3050 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3064 = _3055;\n    }\n    if (_3064)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3070 = _3040 > 1;\n        bool _3077;\n        if (_3070)\n        {\n            _3077 = _3050 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3077 = _3070;\n        }\n        if (_3077)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3083 = _3040 > 2;\n        bool _3090;\n        if (_3083)\n        {\n            _3090 = _3050 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3090 = _3083;\n        }\n        if (_3090)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3096 = _3040 > 3;\n        bool _3103;\n        if (_3096)\n        {\n            _3103 = _3050 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3103 = _3096;\n        }\n        if (_3103)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _5978 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5978 = -_5978;\n    }\n    vec3 _5552 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5978, fa_world_tangent, fa_uv, fa_vertex_color, _5552, gl_FrontFacing);\n    Surface _5560 = fa_standard_surface(param_1);\n    vec3 _6017 = _5560.albedo;\n    float _6018 = _5560.alpha;\n    vec3 _6019 = _5560.normal;\n    float _6020 = _5560.metallic;\n    float _6021 = _5560.roughness;\n    float _6022 = _5560.occlusion;\n    vec3 _6023 = _5560.emission;\n    float _6024 = _5560.clearcoat;\n    float _6025 = _5560.clearcoat_roughness;\n    vec3 _6026 = _5560.sheen_color;\n    float _6027 = _5560.sheen_roughness;\n    float _6028 = _5560.anisotropy;\n    float _6029 = _5560.anisotropy_rotation;\n    float _6030 = _5560.specular;\n    float _6031 = _5560.ior;\n    vec3 _6032 = _5560.specular_color;\n    float _6033 = _5560.transmission;\n    float _6034 = _5560.thickness;\n    vec3 _6035 = _5560.attenuation_color;\n    float _6036 = _5560.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5978, fa_world_tangent, fa_uv, fa_vertex_color, _5552, gl_FrontFacing);\n    Surface param_3 = _5560;\n    surface(param_2, param_3);\n    _6017 = param_3.albedo;\n    _6018 = param_3.alpha;\n    _6019 = param_3.normal;\n    _6020 = param_3.metallic;\n    _6021 = param_3.roughness;\n    _6022 = param_3.occlusion;\n    _6023 = param_3.emission;\n    _6024 = param_3.clearcoat;\n    _6025 = param_3.clearcoat_roughness;\n    _6026 = param_3.sheen_color;\n    _6027 = param_3.sheen_roughness;\n    _6028 = param_3.anisotropy;\n    _6029 = param_3.anisotropy_rotation;\n    _6030 = param_3.specular;\n    _6031 = param_3.ior;\n    _6032 = param_3.specular_color;\n    _6033 = param_3.transmission;\n    _6034 = param_3.thickness;\n    _6035 = param_3.attenuation_color;\n    _6036 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5978;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6017 = param_6;\n    _6019 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6017;\n    }\n    else\n    {\n        vec3 _5599 = _6019;\n        vec3 _5600 = normalize(_5599);\n        _6019 = _5600;\n        vec3 param_8 = _5600;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _5978, fa_world_tangent, fa_uv, fa_vertex_color, _5552, gl_FrontFacing);\n        Surface param_10 = Surface(_6017, _6018, _6019, _6020, _6021, _6022, _6023, _6024, _6025, _6026, _6027, _6028, _6029, _6030, _6031, _6032, _6033, _6034, _6035, _6036);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _5619 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5619; ln++)\n        {\n            int param_12 = ln;\n            int _5632 = fa_cl_light(param_12);\n            int param_13 = _5632;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _5632;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _5978;\n            LightSample _5648 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _5978, fa_world_tangent, fa_uv, fa_vertex_color, _5552, gl_FrontFacing);\n            Surface param_18 = Surface(_6017, _6018, _6019, _6020, _6021, _6022, _6023, _6024, _6025, _6026, _6027, _6028, _6029, _6030, _6031, _6032, _6033, _6034, _6035, _6036);\n            LightSample param_19 = _5648;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _5663 = result;\n    vec3 _5664 = _5663 + _6023;\n    result = _5664;\n    vec3 param_20 = _5664;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5673 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5680;\n    if (!_5673)\n    {\n        _5680 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5680 = _5673;\n    }\n    if (_5680)\n    {\n        vec3 _5689 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5695 = dot(_5689, fa_mesh_fs_params[9].xyz);\n        bool _5699 = fa_mesh_fs_params[9].w > 0.5;\n        float _5700;\n        if (_5699)\n        {\n            _5700 = _5695;\n        }\n        else\n        {\n            _5700 = length(_5689);\n        }\n        float _5712 = _5700 - fa_mesh_fs_params[8].x;\n        if (_5712 > 0.0)\n        {\n            float _5721 = fa_mesh_fs_params[7].w * _5712;\n            float tau = _5721 * _5721;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5737;\n                if (_5699)\n                {\n                    _5737 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5695);\n                }\n                else\n                {\n                    _5737 = fa_mesh_fs_params[0].y;\n                }\n                float _5758 = mix(_5737, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5700, 0.0, 1.0));\n                float _5762 = fa_world_pos.y - _5758;\n                float _5767 = _5758 - fa_mesh_fs_params[8].z;\n                float _5772 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5775 = _5767 <= 0.0;\n                bool _5776 = !_5775;\n                bool _5782;\n                if (_5776)\n                {\n                    _5782 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5782 = _5775;\n                }\n                float _5783;\n                if (_5782)\n                {\n                    _5783 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5783 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5767, 80.0));\n                }\n                bool _5810;\n                if (_5776)\n                {\n                    _5810 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5810 = _5775;\n                }\n                float _5811;\n                if (_5810)\n                {\n                    _5811 = fa_mesh_fs_params[8].y * _5767;\n                }\n                else\n                {\n                    _5811 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5767, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5836 = _5772 <= 0.0;\n                bool _5843;\n                if (!_5836)\n                {\n                    _5843 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5843 = _5836;\n                }\n                float _5844;\n                if (_5843)\n                {\n                    _5844 = fa_mesh_fs_params[8].y * _5772;\n                }\n                else\n                {\n                    _5844 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5772, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5871;\n                if (abs(_5762) < 0.001000000047497451305389404296875)\n                {\n                    _5871 = _5783;\n                }\n                else\n                {\n                    _5871 = (_5844 - _5811) / _5762;\n                }\n                tau += (_5712 * max(_5871, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6018);\n}\n\n",
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
            "inst_name": "_429",
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
            "inst_name": "_2081",
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
