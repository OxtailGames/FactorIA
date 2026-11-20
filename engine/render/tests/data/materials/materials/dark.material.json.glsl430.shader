{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "63c8ed9ef72f0fba56beb38b3018a9ae9876604a67ae71ca005757f89f9b9e64",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1282 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1289;\n    if (!_1282)\n    {\n        _1289 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1289 = _1282;\n    }\n    bool _1297;\n    if (!_1289)\n    {\n        _1297 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1297 = _1289;\n    }\n    bool _1304;\n    if (!_1297)\n    {\n        _1304 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1304 = _1297;\n    }\n    bool _1311;\n    if (!_1304)\n    {\n        _1311 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1311 = _1304;\n    }\n    if (_1311)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1321 = vec4(world_pos, 1.0);\n    float _1327 = dot(fa_mesh_fs_params[16], _1321);\n    if (!(_1327 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1349 = vec2(dot(fa_mesh_fs_params[14], _1321), dot(fa_mesh_fs_params[15], _1321)) / vec2(_1327);\n    int _1353 = int(fa_mesh_fs_params[18].x);\n    int _1357 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1357) + clamp(int(floor(((_1349.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1357 - 1)) * _1353)) + clamp(int(floor(((_1349.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1353 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1433 = fa_cluster_texel(param);\n    return ivec2(int(_1433.x), int(_1433.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3073 = fa_cluster_lookup(param);\n    fa_cl_slot = _3073.x;\n    fa_cl_local = _3073.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3222 = fa_linear_to_srgb(param);\n        c = _3222;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3230 = fa_srgb_to_linear(param_1);\n            c = _3230;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _246;\n    if (i.front_facing)\n    {\n        _246 = i.world_normal;\n    }\n    else\n    {\n        _246 = -i.world_normal;\n    }\n    vec3 _270 = normalize(i.world_tangent.xyz - (_246 * dot(_246, i.world_tangent.xyz)));\n    vec3 _298 = normalize(((_270 * m.x) + ((cross(_246, _270) * i.world_tangent.w) * m.y)) + (_246 * m.z));\n    vec3 _301;\n    if (i.front_facing)\n    {\n        _301 = _298;\n    }\n    else\n    {\n        _301 = -_298;\n    }\n    return _301;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3261 = fa_tex_fix(param_2, param_3);\n    vec4 _4286 = base_t;\n    _4286.x = _3261.x;\n    _4286.y = _3261.y;\n    _4286.z = _3261.z;\n    base_t = _4286;\n    vec4 _3275 = (_4286 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4151 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3307 = fa_tex_fix(param_6, param_7);\n        vec3 _3310 = (_3307 * 2.0) - vec3(1.0);\n        vec2 _3315 = _3310.xy * fa_mesh_fs_params[6].x;\n        vec3 _4294 = _3310;\n        _4294.x = _3315.x;\n        _4294.y = _3315.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4294;\n        _4151 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3343 = fa_tex_fix(param_12, param_13);\n    vec4 _4297 = mrt;\n    _4297.x = _3343.x;\n    _4297.y = _3343.y;\n    _4297.z = _3343.z;\n    mrt = _4297;\n    vec4 _3371 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3371.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3382 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3412 = fa_tex_fix(param_20, param_21);\n    float _4156 = fa_mesh_fs_params[20].x;\n    float _4157 = fa_mesh_fs_params[20].y;\n    float _4160 = fa_mesh_fs_params[20].z;\n    float _4159 = fa_mesh_fs_params[21].w;\n    float _4162 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4156 *= _3382.y;\n            _4157 *= _3382.z;\n            _4159 *= _3371.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4160 *= mrt.x;\n            _4162 *= mrt.w;\n        }\n    }\n    return Surface(_3275.xyz, _3275.w, _4151, clamp(fa_mesh_fs_params[5].x * _3343.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3343.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3382.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3412), _4156, _4157, fa_mesh_fs_params[21].xyz, _4159, _4160, fa_mesh_fs_params[20].w, _4162, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1513 = rect.zw - rect.xy;\n    vec2 _1517 = _1513 * atlas;\n    vec2 _1521 = ddx * _1517;\n    vec2 _1525 = ddy * _1517;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1513), clamp(0.5 * log2(max(max(dot(_1521, _1521), dot(_1525, _1525)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1558 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1565;\n    if (!_1558)\n    {\n        _1565 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1565 = _1558;\n    }\n    if (_1565)\n    {\n        return;\n    }\n    vec3 _1571 = dFdx(world_pos);\n    vec3 _1574 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1578 = fa_cluster_texel(param);\n    int _1582 = int(_1578.w);\n    if (_1582 < 1)\n    {\n        return;\n    }\n    int _1592 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1592;\n    vec4 _1596 = fa_light_texel(param_1);\n    vec2 _1599 = _1596.yz;\n    int _1603 = int(_1596.w);\n    int param_2 = _1592 + 1;\n    vec4 _1608 = fa_light_texel(param_2);\n    float _1609 = _1608.x;\n    int _1615 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1619 = int(_1578.z);\n    vec3 _1884;\n    for (int k = 0; k < _1582; k++)\n    {\n        int _1632 = _1619 + k;\n        int param_3 = _1603 + (_1632 >> 2);\n        int _1649 = (_1592 + 2) + (int(fa_light_texel(param_3)[_1632 & 3]) * 7);\n        int param_4 = _1649 + 6;\n        vec4 _1654 = fa_light_texel(param_4);\n        if (((int(_1654.w + 0.5) >> _1615) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1649;\n        vec4 _1669 = fa_light_texel(param_5);\n        int param_6 = _1649 + 1;\n        vec4 _1674 = fa_light_texel(param_6);\n        int param_7 = _1649 + 2;\n        vec4 _1679 = fa_light_texel(param_7);\n        vec3 _1682 = _1669.xyz;\n        float _1687 = dot(_1682, world_pos) + _1669.w;\n        vec3 _1689 = _1674.xyz;\n        float _1694 = dot(_1689, world_pos) + _1674.w;\n        vec3 _1696 = _1679.xyz;\n        float _1701 = dot(_1696, world_pos) + _1679.w;\n        bool _1706 = abs(_1687) > 0.5;\n        bool _1714;\n        if (!_1706)\n        {\n            _1714 = abs(_1694) > 0.5;\n        }\n        else\n        {\n            _1714 = _1706;\n        }\n        bool _1722;\n        if (!_1714)\n        {\n            _1722 = abs(_1701) > 0.5;\n        }\n        else\n        {\n            _1722 = _1714;\n        }\n        if (_1722)\n        {\n            continue;\n        }\n        float _1737 = clamp(dot(geo_normal, normalize(_1696)) * _1654.z, 0.0, 1.0);\n        if (_1737 <= 0.0)\n        {\n            continue;\n        }\n        float _1757 = (clamp((0.5 - abs(_1701)) * 10.0, 0.0, 1.0) * _1737) * _1654.x;\n        vec2 _1765 = vec2(_1687 + 0.5, 0.5 - _1694);\n        vec2 _1775 = vec2(dot(_1682, _1571), dot(_1689, _1571));\n        vec2 _1785 = vec2(dot(_1682, _1574), dot(_1689, _1574));\n        int param_8 = _1649 + 5;\n        vec4 _1790 = fa_light_texel(param_8);\n        int param_9 = _1649 + 3;\n        vec4 _1795 = fa_light_texel(param_9);\n        int param_10 = _1649 + 4;\n        vec4 _1800 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1790.xyz;\n        bool _1810 = _1795.z > _1795.x;\n        if (_1810)\n        {\n            vec4 param_11 = _1795;\n            vec2 param_12 = _1765;\n            vec2 param_13 = _1599;\n            vec2 param_14 = _1775;\n            vec2 param_15 = _1785;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1609 > 0.5) && (_1609 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1836 = fa_dc_to_linear(param_16);\n                vec4 _4231 = tx;\n                _4231.x = _1836.x;\n                _4231.y = _1836.y;\n                _4231.z = _1836.z;\n                tx = _4231;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1757 * tex_a) * _1790.w, 0.0, 1.0)));\n        if (_1800.z > _1800.x)\n        {\n            vec4 param_17 = _1800;\n            vec2 param_18 = _1765;\n            vec2 param_19 = _1599;\n            vec2 param_20 = _1775;\n            vec2 param_21 = _1785;\n            vec4 _1880 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1609 > 1.5)\n            {\n                vec3 param_22 = _1880.xyz;\n                vec3 _1890 = fa_dc_to_srgb(param_22);\n                _1884 = _1890;\n            }\n            else\n            {\n                _1884 = _1880.xyz;\n            }\n            vec3 _1899 = (_1884 * 2.0) - vec3(1.0);\n            vec2 _1904 = _1899.xy * _1654.y;\n            vec3 _1926 = (normalize(_1682) * _1904.x) + (normalize(_1689) * _1904.y);\n            vec3 _1929 = normalize(normal);\n            normal = normalize(mix(_1929, normalize((_1929 * max(_1899.z, 0.0500000007450580596923828125)) + (_1926 - (_1929 * dot(_1929, _1926)))), vec3(clamp(_1757 * (_1810 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _542 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _555 = (c - (ru * hx)) - p;\n        vec3 _561 = ru * (2.0 * hx);\n        float _567 = max(dot(_561, _561), 9.9999999392252902907785028219223e-09);\n        float _571 = dot(_555, _561);\n        float t = clamp((-_571) / _567, 0.0, 1.0);\n        if (_542)\n        {\n            float _586 = dot(r, _561);\n            float _592 = _567 - (_586 * _586);\n            if (abs(_592) > (9.9999997473787516355514526367188e-06 * _567))\n            {\n                t = clamp(((dot(r, _555) * _586) - _571) / _592, 0.0, 1.0);\n            }\n        }\n        return (p + _555) + (_561 * t);\n    }\n    vec3 q = p;\n    float _624 = dot(r, axis);\n    bool _632;\n    if (_542)\n    {\n        _632 = abs(_624) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _632 = _542;\n    }\n    if (_632)\n    {\n        float _642 = dot(c - p, axis) / _624;\n        if (_642 > 0.0)\n        {\n            q = p + (r * _642);\n        }\n    }\n    vec3 _655 = q - c;\n    vec2 xy = vec2(dot(_655, ru), dot(_655, uu));\n    if (shape > 0.5)\n    {\n        float _670 = length(xy);\n        if (_670 > hx)\n        {\n            xy *= (hx / _670);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _463 = abs(d);\n    float _465 = _463.x;\n    float _467 = _463.y;\n    bool _468 = _465 >= _467;\n    bool _476;\n    if (_468)\n    {\n        _476 = _465 >= _463.z;\n    }\n    else\n    {\n        _476 = _468;\n    }\n    int _477;\n    if (_476)\n    {\n        _477 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _490;\n        if (_467 >= _463.z)\n        {\n            _490 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _490 = (d.z > 0.0) ? 4 : 5;\n        }\n        _477 = _490;\n    }\n    return _477;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _416 = dot(d, right);\n    float _420 = dot(d, up);\n    float _431;\n    if (((_416 * _416) + (_420 * _420)) > 1.0000000133514319600180897396058e-10)\n    {\n        _431 = atan(_420, _416) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _431 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_431 - floor(_431)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _708 = fa_light_base(param);\n    bool _712 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _708;\n    vec4 _716 = fa_light_texel(param_1);\n    int param_2 = _708 + 1;\n    vec4 _721 = fa_light_texel(param_2);\n    float _724 = _721.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _736 = _712 && (_724 > 2.5);\n    fa_light_is_area = _736;\n    bool _738 = _724 < 0.5;\n    vec3 l;\n    if (_738)\n    {\n        l = normalize(_716.xyz);\n        if (_712)\n        {\n            int param_3 = _708 + 6;\n            vec4 _752 = fa_light_texel(param_3);\n            if (_752.z > 0.5)\n            {\n                int param_4 = _708 + 4;\n                vec4 _762 = fa_light_texel(param_4);\n                int param_5 = _708 + 5;\n                vec4 _767 = fa_light_texel(param_5);\n                vec2 param_6 = _752.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _762.xyz) * _762.w, (-dot(world_pos, _767.xyz)) * _767.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _797 = _716.xyz;\n        vec3 _799 = _797 - world_pos;\n        vec3 to_light = _799;\n        float _802 = length(_799);\n        float reach = _802;\n        bool front = true;\n        if (_736)\n        {\n            int param_8 = _708 + 7;\n            reach = max(_802 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _708 + 4;\n            vec4 _826 = fa_light_texel(param_9);\n            int param_10 = _708 + 5;\n            vec4 _831 = fa_light_texel(param_10);\n            int param_11 = _708 + 6;\n            vec4 _836 = fa_light_texel(param_11);\n            float _837 = _836.w;\n            int param_12 = _708 + 2;\n            vec3 _844 = normalize(fa_light_texel(param_12).xyz);\n            bool _846 = _837 > 1.5;\n            bool _854;\n            if (!_846)\n            {\n                _854 = dot(_844, to_light) < 0.0;\n            }\n            else\n            {\n                _854 = _846;\n            }\n            front = _854;\n            vec3 r = vec3(0.0);\n            if (dot(n, n) > 0.5)\n            {\n                r = reflect(-normalize(fa_mesh_fs_params[0].xyz - world_pos), normalize(n));\n            }\n            vec3 param_13 = _797;\n            vec3 param_14 = _844;\n            vec3 param_15 = _826.xyz;\n            vec3 param_16 = _831.xyz;\n            float param_17 = _826.w;\n            float param_18 = _831.w;\n            float param_19 = _837;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _901 = length(to_light);\n        dist = _901;\n        l = to_light / vec3(max(_901, 9.9999997473787516355514526367188e-05));\n        float _915 = reach / max(_716.w, 0.001000000047497451305389404296875);\n        float _921 = clamp(1.0 - (_915 * _915), 0.0, 1.0);\n        float _923;\n        if (front)\n        {\n            _923 = _921 * _921;\n        }\n        else\n        {\n            _923 = 0.0;\n        }\n        atten = _923;\n        bool _934 = _724 < 2.5;\n        if ((_724 > 1.5) && _934)\n        {\n            int param_22 = _708 + 2;\n            vec4 _942 = fa_light_texel(param_22);\n            float _952 = _942.w;\n            int param_23 = _708 + 3;\n            vec4 _957 = fa_light_texel(param_23);\n            float _958 = _957.x;\n            float cos_inner = _958;\n            if (_958 > 1.5)\n            {\n                cos_inner = mix(_952, 1.0, 0.25);\n            }\n            atten *= smoothstep(_952, cos_inner, dot(-l, normalize(_942.xyz)));\n        }\n        if (_712 && (_724 < 1.5))\n        {\n            int param_24 = _708 + 6;\n            vec4 _982 = fa_light_texel(param_24);\n            if (_982.z > 0.5)\n            {\n                vec3 _990 = -to_light;\n                int param_25 = _708 + 4;\n                int param_26 = _708 + 5;\n                vec3 _1004 = fa_light_texel(param_25).xyz;\n                vec3 _1008 = fa_light_texel(param_26).xyz;\n                vec3 _1017 = vec3(dot(_990, _1004), dot(_990, _1008), dot(_990, cross(_1004, _1008)));\n                vec3 param_27 = _1017;\n                int _1021 = fa_cube_face(param_27);\n                int param_28 = _1021;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1048 = vec2(dot(_1017, cross(param_29, param_30)), dot(_1017, param_30)) / vec2(max(dot(_1017, param_29), 9.9999997473787516355514526367188e-05));\n                int _1052 = _1021 / 3;\n                vec2 param_31 = _982.xy + (vec2(float(_1021 - (_1052 * 3)), float(_1052)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1048.x), 0.5 - (0.5 * _1048.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _708 + 7;\n            vec4 _1082 = fa_light_texel(param_33);\n            if (_1082.z > 0.5)\n            {\n                int param_34 = _708 + 2;\n                int param_35 = _708 + 4;\n                int param_36 = _708 + 5;\n                vec2 param_37 = _1082.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_712 && _934)\n            {\n                int param_42 = _708 + 6;\n                vec4 _1129 = fa_light_texel(param_42);\n                int param_43 = _708 + 7;\n                vec4 _1134 = fa_light_texel(param_43);\n                bool _1137 = _1129.z > 0.5;\n                bool _1144;\n                if (!_1137)\n                {\n                    _1144 = _1134.z > 0.5;\n                }\n                else\n                {\n                    _1144 = _1137;\n                }\n                if (_1144)\n                {\n                    int param_44 = _708 + 2;\n                    vec4 _1151 = fa_light_texel(param_44);\n                    vec3 _1155 = normalize(_1151.xyz);\n                    int param_45 = _708 + 4;\n                    vec4 _1160 = fa_light_texel(param_45);\n                    int param_46 = _708 + 5;\n                    vec4 _1165 = fa_light_texel(param_46);\n                    if (_1137)\n                    {\n                        vec3 _1173 = -to_light;\n                        float _1180 = _1151.w;\n                        float _1196 = 0.5 / max(dot(_1173, _1155) * (sqrt(max(1.0 - (_1180 * _1180), 0.0)) / max(_1180, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1129.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1173, _1160.xyz) * _1196), 0.5 - (dot(_1173, _1165.xyz) * _1196));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1134.z > 0.5)\n                    {\n                        vec2 param_49 = _1134.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1155;\n                        vec3 param_52 = _1160.xyz;\n                        vec3 param_53 = _1165.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _4105 = _721.xyz * atten;\n    if (_712)\n    {\n        _4105 *= fa_light_tint;\n    }\n    int _1264;\n    if (_738)\n    {\n        _1264 = 0;\n    }\n    else\n    {\n        _1264 = ((_724 > 1.5) && (_724 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4105, atten, 1.0, dist, _1264);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2001;\n    if (i == 0)\n    {\n        _2001 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2017;\n        if (i == 1)\n        {\n            _2017 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2025;\n            if (i == 2)\n            {\n                _2025 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2025 = fa_shadows[24].w;\n            }\n            _2017 = _2025;\n        }\n        _2001 = _2017;\n    }\n    return _2001;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2058 = fa_shadow_depth(param, param_1);\n    float _2062;\n    if (conv.x < 0.5)\n    {\n        _2062 = _2058;\n    }\n    else\n    {\n        _2062 = (conv.y * conv.z) / (conv.z - (_2058 * (conv.z - conv.y)));\n    }\n    return _2062;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1989 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1989), sin(_1989)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2108 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2117;\n        if (k < 0.0)\n        {\n            _2117 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2117 = k;\n        }\n        float _2137 = clamp((_2117 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2108;\n            vec2 _2156 = fa_shadow_vogel(param_3, param_4, param_5) * _2137;\n            vec2 param_6 = uv + (_2156 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2168 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2168 < (zr - (length(_2156) * plane)))\n            {\n                sum += _2168;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2194 = sum / cnt;\n        float _2204;\n        if (k < 0.0)\n        {\n            _2204 = (-k) / max(_2194, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2204 = k;\n        }\n        radius = clamp(((max(zr - _2194, 0.0) * unit) * _2204) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2226 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2226; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2226;\n        float param_11 = _2108;\n        vec2 _2245 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2245 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2245) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2226);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2287 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2292 = clamp(dot(n, l), 0.0, 1.0);\n    float _2298 = sqrt(1.0 - (_2292 * _2292));\n    float _2305 = min(_2298 / max(_2292, 0.20000000298023223876953125), 4.0);\n    float _2310;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2310 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2310 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2335 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2310 * _2298)), 1.0);\n    float _2342 = _2335.x;\n    bool _2345 = _2342 < fa_shadows[ci * 1 + 16].x;\n    bool _2354;\n    if (!_2345)\n    {\n        _2354 = _2342 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2354 = _2345;\n    }\n    bool _2363;\n    if (!_2354)\n    {\n        _2363 = _2335.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2363 = _2354;\n    }\n    bool _2372;\n    if (!_2363)\n    {\n        _2372 = _2335.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2372 = _2363;\n    }\n    bool _2379;\n    if (!_2372)\n    {\n        _2379 = _2335.z > 1.0;\n    }\n    else\n    {\n        _2379 = _2372;\n    }\n    if (_2379)\n    {\n        return -1.0;\n    }\n    float _2387;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2387 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2387 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2335.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2335.z - ((_2387 * (1.0 + (0.5 * _2305))) / _2287);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2287;\n    float param_5 = _2287 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2305, 3.0)) * 0.5) / _2287;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2775 = int(fa_shadows[25].x + 0.5);\n    if (_2775 < 1)\n    {\n        return 1.0;\n    }\n    float _2790 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2775 - 1;\n    if (_2790 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2802 = _2775 > 1;\n    bool _2809;\n    if (_2802)\n    {\n        _2809 = _2790 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2809 = _2802;\n    }\n    if (_2809)\n    {\n        ci = 1;\n    }\n    bool _2813 = _2775 > 2;\n    bool _2820;\n    if (_2813)\n    {\n        _2820 = _2790 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2820 = _2813;\n    }\n    if (_2820)\n    {\n        ci = 2;\n    }\n    bool _2824 = _2775 > 3;\n    bool _2831;\n    if (_2824)\n    {\n        _2831 = _2790 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2831 = _2824;\n    }\n    if (_2831)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2775)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2857 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2857;\n        if (_2857 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2882;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2882 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2882 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2901 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2882, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2912 = clamp((_2790 - (fa_shadow_split_at(param_7) - _2901)) / _2901, 0.0, 1.0);\n        if (_2912 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2775)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2933 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2933;\n                if (_2933 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2912);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _2445 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2452;\n    if (!_2445)\n    {\n        _2452 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2452 = _2445;\n    }\n    if (_2452)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2465 = fa_light_texel(param);\n    float _2466 = _2465.x;\n    if (_2466 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2475 = int(_2466 + 0.5);\n    int param_1 = _2475;\n    vec4 _2479 = fa_light_texel(param_1);\n    int param_2 = _2475 + 1;\n    vec4 _2484 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2487 = _2479.y;\n    if (_2487 > 0.0)\n    {\n        float _2504 = 1.0 - smoothstep(0.75 * _2487, _2487, length(world - fa_shadows[27].xyz));\n        fade = _2504;\n        if (_2504 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2479.x > 1.5)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        vec3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2533 = (_2475 + 2) + (face * 6);\n    int param_6 = _2533;\n    int param_7 = _2533 + 1;\n    int param_8 = _2533 + 3;\n    vec4 _2547 = fa_light_texel(param_8);\n    int param_9 = _2533 + 4;\n    vec4 _2552 = fa_light_texel(param_9);\n    int param_10 = _2533 + 5;\n    vec4 _2557 = fa_light_texel(param_10);\n    float _2569 = _2557.x * max(dot(_2547, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2574 = clamp(dot(n, l), 0.0, 1.0);\n    float _2597 = clamp(dot(n, _2547.xyz), -1.0, 1.0);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2621 = min(sqrt(1.0 - (_2597 * _2597)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2547, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2624 = _2484.y;\n    float _2626;\n    if (_2624 > 0.0)\n    {\n        _2626 = _2624;\n    }\n    else\n    {\n        _2626 = 1.5 * _2569;\n    }\n    vec4 _2646 = vec4(world + (n * (_2626 * sqrt(1.0 - (_2574 * _2574)))), 1.0);\n    float _2650 = dot(_2547, _2646);\n    float _2653 = _2557.y;\n    if (_2650 < _2653)\n    {\n        return 1.0;\n    }\n    vec2 _2668 = vec2(dot(fa_light_texel(param_6), _2646), dot(fa_light_texel(param_7), _2646)) / vec2(_2650);\n    float _2670 = _2668.x;\n    bool _2673 = _2670 < _2552.x;\n    bool _2682;\n    if (!_2673)\n    {\n        _2682 = _2670 > _2552.z;\n    }\n    else\n    {\n        _2682 = _2673;\n    }\n    bool _2691;\n    if (!_2682)\n    {\n        _2691 = _2668.y < _2552.y;\n    }\n    else\n    {\n        _2691 = _2682;\n    }\n    bool _2700;\n    if (!_2691)\n    {\n        _2700 = _2668.y > _2552.w;\n    }\n    else\n    {\n        _2700 = _2691;\n    }\n    if (_2700)\n    {\n        return 1.0;\n    }\n    float _2706 = _2484.x;\n    float _2708;\n    if (_2706 > 0.0)\n    {\n        _2708 = _2706;\n    }\n    else\n    {\n        _2708 = 1.5 * _2569;\n    }\n    vec2 param_13 = _2668;\n    vec4 param_14 = _2552;\n    float param_15 = _2650 - (_2708 * (1.0 + (0.5 * _2621)));\n    float param_16 = _2569;\n    float param_17 = 1.0;\n    float param_18 = _2557.z * 0.25;\n    float param_19 = (_2569 * min(_2621, 3.0)) * 0.5;\n    vec3 param_20 = vec3(1.0, _2653, _2557.z);\n    int param_21 = int(_2479.z + 0.5);\n    float param_22 = _2479.w;\n    return mix(1.0, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3100 = fa_lm.z > 0.5;\n    bool _3106;\n    if (_3100)\n    {\n        int param = li;\n        _3106 = fa_light_baked(param);\n    }\n    else\n    {\n        _3106 = _3100;\n    }\n    if (_3106)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3130 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _4131 = _3130.color;\n    float _4133 = _3130.shadow;\n    if ((_3130.type == 0) && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3130.direction;\n        float _3144 = fa_shadow_factor(param_5, param_6);\n        _4133 = _3144;\n        _4131 *= _3144;\n    }\n    else\n    {\n        bool _3155 = _3130.type != 0;\n        bool _3161;\n        if (_3155)\n        {\n            _3161 = _3130.attenuation > 0.0;\n        }\n        else\n        {\n            _3161 = _3155;\n        }\n        if (_3161)\n        {\n            int param_7 = li;\n            vec3 param_8 = world_pos;\n            vec3 param_9 = gn;\n            vec3 param_10 = _3130.direction;\n            float _3173 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _4133 = _3173;\n            _4131 *= _3173;\n        }\n    }\n    return LightSample(_3130.direction, _4131, _3130.attenuation, _4133, _3130._distance, _3130.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2957 = int(fa_shadows[25].x + 0.5);\n    float _2967 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2972 = _2957 > 0;\n    bool _2981;\n    if (_2972)\n    {\n        int param = _2957 - 1;\n        _2981 = _2967 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2981 = _2972;\n    }\n    if (_2981)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2987 = _2957 > 1;\n        bool _2994;\n        if (_2987)\n        {\n            _2994 = _2967 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2994 = _2987;\n        }\n        if (_2994)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3000 = _2957 > 2;\n        bool _3007;\n        if (_3000)\n        {\n            _3007 = _2967 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3007 = _3000;\n        }\n        if (_3007)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3013 = _2957 > 3;\n        bool _3020;\n        if (_3013)\n        {\n            _3020 = _2967 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3020 = _3013;\n        }\n        if (_3020)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3972 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3972 = -_3972;\n    }\n    vec3 _3556 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3972, fa_world_tangent, fa_uv, fa_vertex_color, _3556, gl_FrontFacing);\n    Surface _3564 = fa_standard_surface(param_1);\n    vec3 _4003 = _3564.albedo;\n    float _4004 = _3564.alpha;\n    vec3 _4005 = _3564.normal;\n    float _4006 = _3564.metallic;\n    float _4007 = _3564.roughness;\n    float _4008 = _3564.occlusion;\n    vec3 _4009 = _3564.emission;\n    float _4010 = _3564.clearcoat;\n    float _4011 = _3564.clearcoat_roughness;\n    vec3 _4012 = _3564.sheen_color;\n    float _4013 = _3564.sheen_roughness;\n    float _4014 = _3564.anisotropy;\n    float _4015 = _3564.anisotropy_rotation;\n    float _4016 = _3564.specular;\n    float _4017 = _3564.ior;\n    vec3 _4018 = _3564.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3972, fa_world_tangent, fa_uv, fa_vertex_color, _3556, gl_FrontFacing);\n    Surface param_3 = _3564;\n    surface(param_2, param_3);\n    _4003 = param_3.albedo;\n    _4004 = param_3.alpha;\n    _4005 = param_3.normal;\n    _4006 = param_3.metallic;\n    _4007 = param_3.roughness;\n    _4008 = param_3.occlusion;\n    _4009 = param_3.emission;\n    _4010 = param_3.clearcoat;\n    _4011 = param_3.clearcoat_roughness;\n    _4012 = param_3.sheen_color;\n    _4013 = param_3.sheen_roughness;\n    _4014 = param_3.anisotropy;\n    _4015 = param_3.anisotropy_rotation;\n    _4016 = param_3.specular;\n    _4017 = param_3.ior;\n    _4018 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _3972;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4003 = param_6;\n    _4005 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4003;\n    }\n    else\n    {\n        vec3 _3602 = _4005;\n        vec3 _3603 = normalize(_3602);\n        _4005 = _3603;\n        vec3 param_8 = _3603;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _4003) * _4008;\n        int _3622 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3622; ln++)\n        {\n            int param_9 = ln;\n            int _3635 = fa_cl_light(param_9);\n            bool _3638 = fa_lm.z > 0.5;\n            bool _3644;\n            if (_3638)\n            {\n                int param_10 = _3635;\n                _3644 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _3644 = _3638;\n            }\n            if (_3644)\n            {\n                continue;\n            }\n            int param_11 = _3635;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _3972;\n            LightSample _3656 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _3972, fa_world_tangent, fa_uv, fa_vertex_color, _3556, gl_FrontFacing);\n            Surface param_15 = Surface(_4003, _4004, _4005, _4006, _4007, _4008, _4009, _4010, _4011, _4012, _4013, _4014, _4015, _4016, _4017, _4018);\n            LightSample param_16 = _3656;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _3671 = result;\n    vec3 _3672 = _3671 + _4009;\n    result = _3672;\n    vec3 param_17 = _3672;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _3681 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3688;\n    if (!_3681)\n    {\n        _3688 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3688 = _3681;\n    }\n    if (_3688)\n    {\n        vec3 _3697 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3703 = dot(_3697, fa_mesh_fs_params[9].xyz);\n        bool _3707 = fa_mesh_fs_params[9].w > 0.5;\n        float _3708;\n        if (_3707)\n        {\n            _3708 = _3703;\n        }\n        else\n        {\n            _3708 = length(_3697);\n        }\n        float _3720 = _3708 - fa_mesh_fs_params[8].x;\n        if (_3720 > 0.0)\n        {\n            float _3729 = fa_mesh_fs_params[7].w * _3720;\n            float tau = _3729 * _3729;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3745;\n                if (_3707)\n                {\n                    _3745 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3703);\n                }\n                else\n                {\n                    _3745 = fa_mesh_fs_params[0].y;\n                }\n                float _3766 = mix(_3745, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3708, 0.0, 1.0));\n                float _3770 = fa_world_pos.y - _3766;\n                float _3775 = _3766 - fa_mesh_fs_params[8].z;\n                float _3780 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3783 = _3775 <= 0.0;\n                bool _3784 = !_3783;\n                bool _3790;\n                if (_3784)\n                {\n                    _3790 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3790 = _3783;\n                }\n                float _3791;\n                if (_3790)\n                {\n                    _3791 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3791 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3775, 80.0));\n                }\n                bool _3818;\n                if (_3784)\n                {\n                    _3818 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3818 = _3783;\n                }\n                float _3819;\n                if (_3818)\n                {\n                    _3819 = fa_mesh_fs_params[8].y * _3775;\n                }\n                else\n                {\n                    _3819 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3775, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3844 = _3780 <= 0.0;\n                bool _3851;\n                if (!_3844)\n                {\n                    _3851 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3851 = _3844;\n                }\n                float _3852;\n                if (_3851)\n                {\n                    _3852 = fa_mesh_fs_params[8].y * _3780;\n                }\n                else\n                {\n                    _3852 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3780, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3879;\n                if (abs(_3770) < 0.001000000047497451305389404296875)\n                {\n                    _3879 = _3791;\n                }\n                else\n                {\n                    _3879 = (_3852 - _3819) / _3770;\n                }\n                tau += (_3720 * max(_3879, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4004);\n}\n\n",
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
            "inst_name": "_314",
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
            "inst_name": "_2011",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1282 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1289;\n    if (!_1282)\n    {\n        _1289 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1289 = _1282;\n    }\n    bool _1297;\n    if (!_1289)\n    {\n        _1297 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1297 = _1289;\n    }\n    bool _1304;\n    if (!_1297)\n    {\n        _1304 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1304 = _1297;\n    }\n    bool _1311;\n    if (!_1304)\n    {\n        _1311 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1311 = _1304;\n    }\n    if (_1311)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1321 = vec4(world_pos, 1.0);\n    float _1327 = dot(fa_mesh_fs_params[16], _1321);\n    if (!(_1327 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1349 = vec2(dot(fa_mesh_fs_params[14], _1321), dot(fa_mesh_fs_params[15], _1321)) / vec2(_1327);\n    int _1353 = int(fa_mesh_fs_params[18].x);\n    int _1357 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1357) + clamp(int(floor(((_1349.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1357 - 1)) * _1353)) + clamp(int(floor(((_1349.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1353 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1433 = fa_cluster_texel(param);\n    return ivec2(int(_1433.x), int(_1433.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3073 = fa_cluster_lookup(param);\n    fa_cl_slot = _3073.x;\n    fa_cl_local = _3073.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3222 = fa_linear_to_srgb(param);\n        c = _3222;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3230 = fa_srgb_to_linear(param_1);\n            c = _3230;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _246;\n    if (i.front_facing)\n    {\n        _246 = i.world_normal;\n    }\n    else\n    {\n        _246 = -i.world_normal;\n    }\n    vec3 _270 = normalize(i.world_tangent.xyz - (_246 * dot(_246, i.world_tangent.xyz)));\n    vec3 _298 = normalize(((_270 * m.x) + ((cross(_246, _270) * i.world_tangent.w) * m.y)) + (_246 * m.z));\n    vec3 _301;\n    if (i.front_facing)\n    {\n        _301 = _298;\n    }\n    else\n    {\n        _301 = -_298;\n    }\n    return _301;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3261 = fa_tex_fix(param_2, param_3);\n    vec4 _4286 = base_t;\n    _4286.x = _3261.x;\n    _4286.y = _3261.y;\n    _4286.z = _3261.z;\n    base_t = _4286;\n    vec4 _3275 = (_4286 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4151 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3307 = fa_tex_fix(param_6, param_7);\n        vec3 _3310 = (_3307 * 2.0) - vec3(1.0);\n        vec2 _3315 = _3310.xy * fa_mesh_fs_params[6].x;\n        vec3 _4294 = _3310;\n        _4294.x = _3315.x;\n        _4294.y = _3315.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4294;\n        _4151 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3343 = fa_tex_fix(param_12, param_13);\n    vec4 _4297 = mrt;\n    _4297.x = _3343.x;\n    _4297.y = _3343.y;\n    _4297.z = _3343.z;\n    mrt = _4297;\n    vec4 _3371 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3371.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3382 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3412 = fa_tex_fix(param_20, param_21);\n    float _4156 = fa_mesh_fs_params[20].x;\n    float _4157 = fa_mesh_fs_params[20].y;\n    float _4160 = fa_mesh_fs_params[20].z;\n    float _4159 = fa_mesh_fs_params[21].w;\n    float _4162 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4156 *= _3382.y;\n            _4157 *= _3382.z;\n            _4159 *= _3371.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4160 *= mrt.x;\n            _4162 *= mrt.w;\n        }\n    }\n    return Surface(_3275.xyz, _3275.w, _4151, clamp(fa_mesh_fs_params[5].x * _3343.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3343.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3382.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3412), _4156, _4157, fa_mesh_fs_params[21].xyz, _4159, _4160, fa_mesh_fs_params[20].w, _4162, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1513 = rect.zw - rect.xy;\n    vec2 _1517 = _1513 * atlas;\n    vec2 _1521 = ddx * _1517;\n    vec2 _1525 = ddy * _1517;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1513), clamp(0.5 * log2(max(max(dot(_1521, _1521), dot(_1525, _1525)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1558 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1565;\n    if (!_1558)\n    {\n        _1565 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1565 = _1558;\n    }\n    if (_1565)\n    {\n        return;\n    }\n    vec3 _1571 = dFdx(world_pos);\n    vec3 _1574 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1578 = fa_cluster_texel(param);\n    int _1582 = int(_1578.w);\n    if (_1582 < 1)\n    {\n        return;\n    }\n    int _1592 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1592;\n    vec4 _1596 = fa_light_texel(param_1);\n    vec2 _1599 = _1596.yz;\n    int _1603 = int(_1596.w);\n    int param_2 = _1592 + 1;\n    vec4 _1608 = fa_light_texel(param_2);\n    float _1609 = _1608.x;\n    int _1615 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1619 = int(_1578.z);\n    vec3 _1884;\n    for (int k = 0; k < _1582; k++)\n    {\n        int _1632 = _1619 + k;\n        int param_3 = _1603 + (_1632 >> 2);\n        int _1649 = (_1592 + 2) + (int(fa_light_texel(param_3)[_1632 & 3]) * 7);\n        int param_4 = _1649 + 6;\n        vec4 _1654 = fa_light_texel(param_4);\n        if (((int(_1654.w + 0.5) >> _1615) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1649;\n        vec4 _1669 = fa_light_texel(param_5);\n        int param_6 = _1649 + 1;\n        vec4 _1674 = fa_light_texel(param_6);\n        int param_7 = _1649 + 2;\n        vec4 _1679 = fa_light_texel(param_7);\n        vec3 _1682 = _1669.xyz;\n        float _1687 = dot(_1682, world_pos) + _1669.w;\n        vec3 _1689 = _1674.xyz;\n        float _1694 = dot(_1689, world_pos) + _1674.w;\n        vec3 _1696 = _1679.xyz;\n        float _1701 = dot(_1696, world_pos) + _1679.w;\n        bool _1706 = abs(_1687) > 0.5;\n        bool _1714;\n        if (!_1706)\n        {\n            _1714 = abs(_1694) > 0.5;\n        }\n        else\n        {\n            _1714 = _1706;\n        }\n        bool _1722;\n        if (!_1714)\n        {\n            _1722 = abs(_1701) > 0.5;\n        }\n        else\n        {\n            _1722 = _1714;\n        }\n        if (_1722)\n        {\n            continue;\n        }\n        float _1737 = clamp(dot(geo_normal, normalize(_1696)) * _1654.z, 0.0, 1.0);\n        if (_1737 <= 0.0)\n        {\n            continue;\n        }\n        float _1757 = (clamp((0.5 - abs(_1701)) * 10.0, 0.0, 1.0) * _1737) * _1654.x;\n        vec2 _1765 = vec2(_1687 + 0.5, 0.5 - _1694);\n        vec2 _1775 = vec2(dot(_1682, _1571), dot(_1689, _1571));\n        vec2 _1785 = vec2(dot(_1682, _1574), dot(_1689, _1574));\n        int param_8 = _1649 + 5;\n        vec4 _1790 = fa_light_texel(param_8);\n        int param_9 = _1649 + 3;\n        vec4 _1795 = fa_light_texel(param_9);\n        int param_10 = _1649 + 4;\n        vec4 _1800 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1790.xyz;\n        bool _1810 = _1795.z > _1795.x;\n        if (_1810)\n        {\n            vec4 param_11 = _1795;\n            vec2 param_12 = _1765;\n            vec2 param_13 = _1599;\n            vec2 param_14 = _1775;\n            vec2 param_15 = _1785;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1609 > 0.5) && (_1609 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1836 = fa_dc_to_linear(param_16);\n                vec4 _4231 = tx;\n                _4231.x = _1836.x;\n                _4231.y = _1836.y;\n                _4231.z = _1836.z;\n                tx = _4231;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1757 * tex_a) * _1790.w, 0.0, 1.0)));\n        if (_1800.z > _1800.x)\n        {\n            vec4 param_17 = _1800;\n            vec2 param_18 = _1765;\n            vec2 param_19 = _1599;\n            vec2 param_20 = _1775;\n            vec2 param_21 = _1785;\n            vec4 _1880 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1609 > 1.5)\n            {\n                vec3 param_22 = _1880.xyz;\n                vec3 _1890 = fa_dc_to_srgb(param_22);\n                _1884 = _1890;\n            }\n            else\n            {\n                _1884 = _1880.xyz;\n            }\n            vec3 _1899 = (_1884 * 2.0) - vec3(1.0);\n            vec2 _1904 = _1899.xy * _1654.y;\n            vec3 _1926 = (normalize(_1682) * _1904.x) + (normalize(_1689) * _1904.y);\n            vec3 _1929 = normalize(normal);\n            normal = normalize(mix(_1929, normalize((_1929 * max(_1899.z, 0.0500000007450580596923828125)) + (_1926 - (_1929 * dot(_1929, _1926)))), vec3(clamp(_1757 * (_1810 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _542 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _555 = (c - (ru * hx)) - p;\n        vec3 _561 = ru * (2.0 * hx);\n        float _567 = max(dot(_561, _561), 9.9999999392252902907785028219223e-09);\n        float _571 = dot(_555, _561);\n        float t = clamp((-_571) / _567, 0.0, 1.0);\n        if (_542)\n        {\n            float _586 = dot(r, _561);\n            float _592 = _567 - (_586 * _586);\n            if (abs(_592) > (9.9999997473787516355514526367188e-06 * _567))\n            {\n                t = clamp(((dot(r, _555) * _586) - _571) / _592, 0.0, 1.0);\n            }\n        }\n        return (p + _555) + (_561 * t);\n    }\n    vec3 q = p;\n    float _624 = dot(r, axis);\n    bool _632;\n    if (_542)\n    {\n        _632 = abs(_624) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _632 = _542;\n    }\n    if (_632)\n    {\n        float _642 = dot(c - p, axis) / _624;\n        if (_642 > 0.0)\n        {\n            q = p + (r * _642);\n        }\n    }\n    vec3 _655 = q - c;\n    vec2 xy = vec2(dot(_655, ru), dot(_655, uu));\n    if (shape > 0.5)\n    {\n        float _670 = length(xy);\n        if (_670 > hx)\n        {\n            xy *= (hx / _670);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _463 = abs(d);\n    float _465 = _463.x;\n    float _467 = _463.y;\n    bool _468 = _465 >= _467;\n    bool _476;\n    if (_468)\n    {\n        _476 = _465 >= _463.z;\n    }\n    else\n    {\n        _476 = _468;\n    }\n    int _477;\n    if (_476)\n    {\n        _477 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _490;\n        if (_467 >= _463.z)\n        {\n            _490 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _490 = (d.z > 0.0) ? 4 : 5;\n        }\n        _477 = _490;\n    }\n    return _477;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _416 = dot(d, right);\n    float _420 = dot(d, up);\n    float _431;\n    if (((_416 * _416) + (_420 * _420)) > 1.0000000133514319600180897396058e-10)\n    {\n        _431 = atan(_420, _416) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _431 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_431 - floor(_431)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _708 = fa_light_base(param);\n    bool _712 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _708;\n    vec4 _716 = fa_light_texel(param_1);\n    int param_2 = _708 + 1;\n    vec4 _721 = fa_light_texel(param_2);\n    float _724 = _721.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _736 = _712 && (_724 > 2.5);\n    fa_light_is_area = _736;\n    bool _738 = _724 < 0.5;\n    vec3 l;\n    if (_738)\n    {\n        l = normalize(_716.xyz);\n        if (_712)\n        {\n            int param_3 = _708 + 6;\n            vec4 _752 = fa_light_texel(param_3);\n            if (_752.z > 0.5)\n            {\n                int param_4 = _708 + 4;\n                vec4 _762 = fa_light_texel(param_4);\n                int param_5 = _708 + 5;\n                vec4 _767 = fa_light_texel(param_5);\n                vec2 param_6 = _752.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _762.xyz) * _762.w, (-dot(world_pos, _767.xyz)) * _767.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _797 = _716.xyz;\n        vec3 _799 = _797 - world_pos;\n        vec3 to_light = _799;\n        float _802 = length(_799);\n        float reach = _802;\n        bool front = true;\n        if (_736)\n        {\n            int param_8 = _708 + 7;\n            reach = max(_802 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _708 + 4;\n            vec4 _826 = fa_light_texel(param_9);\n            int param_10 = _708 + 5;\n            vec4 _831 = fa_light_texel(param_10);\n            int param_11 = _708 + 6;\n            vec4 _836 = fa_light_texel(param_11);\n            float _837 = _836.w;\n            int param_12 = _708 + 2;\n            vec3 _844 = normalize(fa_light_texel(param_12).xyz);\n            bool _846 = _837 > 1.5;\n            bool _854;\n            if (!_846)\n            {\n                _854 = dot(_844, to_light) < 0.0;\n            }\n            else\n            {\n                _854 = _846;\n            }\n            front = _854;\n            vec3 r = vec3(0.0);\n            if (dot(n, n) > 0.5)\n            {\n                r = reflect(-normalize(fa_mesh_fs_params[0].xyz - world_pos), normalize(n));\n            }\n            vec3 param_13 = _797;\n            vec3 param_14 = _844;\n            vec3 param_15 = _826.xyz;\n            vec3 param_16 = _831.xyz;\n            float param_17 = _826.w;\n            float param_18 = _831.w;\n            float param_19 = _837;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _901 = length(to_light);\n        dist = _901;\n        l = to_light / vec3(max(_901, 9.9999997473787516355514526367188e-05));\n        float _915 = reach / max(_716.w, 0.001000000047497451305389404296875);\n        float _921 = clamp(1.0 - (_915 * _915), 0.0, 1.0);\n        float _923;\n        if (front)\n        {\n            _923 = _921 * _921;\n        }\n        else\n        {\n            _923 = 0.0;\n        }\n        atten = _923;\n        bool _934 = _724 < 2.5;\n        if ((_724 > 1.5) && _934)\n        {\n            int param_22 = _708 + 2;\n            vec4 _942 = fa_light_texel(param_22);\n            float _952 = _942.w;\n            int param_23 = _708 + 3;\n            vec4 _957 = fa_light_texel(param_23);\n            float _958 = _957.x;\n            float cos_inner = _958;\n            if (_958 > 1.5)\n            {\n                cos_inner = mix(_952, 1.0, 0.25);\n            }\n            atten *= smoothstep(_952, cos_inner, dot(-l, normalize(_942.xyz)));\n        }\n        if (_712 && (_724 < 1.5))\n        {\n            int param_24 = _708 + 6;\n            vec4 _982 = fa_light_texel(param_24);\n            if (_982.z > 0.5)\n            {\n                vec3 _990 = -to_light;\n                int param_25 = _708 + 4;\n                int param_26 = _708 + 5;\n                vec3 _1004 = fa_light_texel(param_25).xyz;\n                vec3 _1008 = fa_light_texel(param_26).xyz;\n                vec3 _1017 = vec3(dot(_990, _1004), dot(_990, _1008), dot(_990, cross(_1004, _1008)));\n                vec3 param_27 = _1017;\n                int _1021 = fa_cube_face(param_27);\n                int param_28 = _1021;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1048 = vec2(dot(_1017, cross(param_29, param_30)), dot(_1017, param_30)) / vec2(max(dot(_1017, param_29), 9.9999997473787516355514526367188e-05));\n                int _1052 = _1021 / 3;\n                vec2 param_31 = _982.xy + (vec2(float(_1021 - (_1052 * 3)), float(_1052)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1048.x), 0.5 - (0.5 * _1048.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _708 + 7;\n            vec4 _1082 = fa_light_texel(param_33);\n            if (_1082.z > 0.5)\n            {\n                int param_34 = _708 + 2;\n                int param_35 = _708 + 4;\n                int param_36 = _708 + 5;\n                vec2 param_37 = _1082.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_712 && _934)\n            {\n                int param_42 = _708 + 6;\n                vec4 _1129 = fa_light_texel(param_42);\n                int param_43 = _708 + 7;\n                vec4 _1134 = fa_light_texel(param_43);\n                bool _1137 = _1129.z > 0.5;\n                bool _1144;\n                if (!_1137)\n                {\n                    _1144 = _1134.z > 0.5;\n                }\n                else\n                {\n                    _1144 = _1137;\n                }\n                if (_1144)\n                {\n                    int param_44 = _708 + 2;\n                    vec4 _1151 = fa_light_texel(param_44);\n                    vec3 _1155 = normalize(_1151.xyz);\n                    int param_45 = _708 + 4;\n                    vec4 _1160 = fa_light_texel(param_45);\n                    int param_46 = _708 + 5;\n                    vec4 _1165 = fa_light_texel(param_46);\n                    if (_1137)\n                    {\n                        vec3 _1173 = -to_light;\n                        float _1180 = _1151.w;\n                        float _1196 = 0.5 / max(dot(_1173, _1155) * (sqrt(max(1.0 - (_1180 * _1180), 0.0)) / max(_1180, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1129.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1173, _1160.xyz) * _1196), 0.5 - (dot(_1173, _1165.xyz) * _1196));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1134.z > 0.5)\n                    {\n                        vec2 param_49 = _1134.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1155;\n                        vec3 param_52 = _1160.xyz;\n                        vec3 param_53 = _1165.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _4105 = _721.xyz * atten;\n    if (_712)\n    {\n        _4105 *= fa_light_tint;\n    }\n    int _1264;\n    if (_738)\n    {\n        _1264 = 0;\n    }\n    else\n    {\n        _1264 = ((_724 > 1.5) && (_724 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4105, atten, 1.0, dist, _1264);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2001;\n    if (i == 0)\n    {\n        _2001 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2017;\n        if (i == 1)\n        {\n            _2017 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2025;\n            if (i == 2)\n            {\n                _2025 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2025 = fa_shadows[24].w;\n            }\n            _2017 = _2025;\n        }\n        _2001 = _2017;\n    }\n    return _2001;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2058 = fa_shadow_depth(param, param_1);\n    float _2062;\n    if (conv.x < 0.5)\n    {\n        _2062 = _2058;\n    }\n    else\n    {\n        _2062 = (conv.y * conv.z) / (conv.z - (_2058 * (conv.z - conv.y)));\n    }\n    return _2062;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1989 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1989), sin(_1989)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2108 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2117;\n        if (k < 0.0)\n        {\n            _2117 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2117 = k;\n        }\n        float _2137 = clamp((_2117 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2108;\n            vec2 _2156 = fa_shadow_vogel(param_3, param_4, param_5) * _2137;\n            vec2 param_6 = uv + (_2156 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2168 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2168 < (zr - (length(_2156) * plane)))\n            {\n                sum += _2168;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2194 = sum / cnt;\n        float _2204;\n        if (k < 0.0)\n        {\n            _2204 = (-k) / max(_2194, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2204 = k;\n        }\n        radius = clamp(((max(zr - _2194, 0.0) * unit) * _2204) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2226 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2226; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2226;\n        float param_11 = _2108;\n        vec2 _2245 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2245 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2245) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2226);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2287 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2292 = clamp(dot(n, l), 0.0, 1.0);\n    float _2298 = sqrt(1.0 - (_2292 * _2292));\n    float _2305 = min(_2298 / max(_2292, 0.20000000298023223876953125), 4.0);\n    float _2310;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2310 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2310 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2335 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2310 * _2298)), 1.0);\n    float _2342 = _2335.x;\n    bool _2345 = _2342 < fa_shadows[ci * 1 + 16].x;\n    bool _2354;\n    if (!_2345)\n    {\n        _2354 = _2342 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2354 = _2345;\n    }\n    bool _2363;\n    if (!_2354)\n    {\n        _2363 = _2335.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2363 = _2354;\n    }\n    bool _2372;\n    if (!_2363)\n    {\n        _2372 = _2335.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2372 = _2363;\n    }\n    bool _2379;\n    if (!_2372)\n    {\n        _2379 = _2335.z > 1.0;\n    }\n    else\n    {\n        _2379 = _2372;\n    }\n    if (_2379)\n    {\n        return -1.0;\n    }\n    float _2387;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2387 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2387 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2335.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2335.z - ((_2387 * (1.0 + (0.5 * _2305))) / _2287);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2287;\n    float param_5 = _2287 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2305, 3.0)) * 0.5) / _2287;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2775 = int(fa_shadows[25].x + 0.5);\n    if (_2775 < 1)\n    {\n        return 1.0;\n    }\n    float _2790 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2775 - 1;\n    if (_2790 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2802 = _2775 > 1;\n    bool _2809;\n    if (_2802)\n    {\n        _2809 = _2790 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2809 = _2802;\n    }\n    if (_2809)\n    {\n        ci = 1;\n    }\n    bool _2813 = _2775 > 2;\n    bool _2820;\n    if (_2813)\n    {\n        _2820 = _2790 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2820 = _2813;\n    }\n    if (_2820)\n    {\n        ci = 2;\n    }\n    bool _2824 = _2775 > 3;\n    bool _2831;\n    if (_2824)\n    {\n        _2831 = _2790 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2831 = _2824;\n    }\n    if (_2831)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2775)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2857 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2857;\n        if (_2857 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2882;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2882 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2882 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2901 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2882, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2912 = clamp((_2790 - (fa_shadow_split_at(param_7) - _2901)) / _2901, 0.0, 1.0);\n        if (_2912 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2775)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2933 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2933;\n                if (_2933 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2912);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _2445 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2452;\n    if (!_2445)\n    {\n        _2452 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2452 = _2445;\n    }\n    if (_2452)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2465 = fa_light_texel(param);\n    float _2466 = _2465.x;\n    if (_2466 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2475 = int(_2466 + 0.5);\n    int param_1 = _2475;\n    vec4 _2479 = fa_light_texel(param_1);\n    int param_2 = _2475 + 1;\n    vec4 _2484 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2487 = _2479.y;\n    if (_2487 > 0.0)\n    {\n        float _2504 = 1.0 - smoothstep(0.75 * _2487, _2487, length(world - fa_shadows[27].xyz));\n        fade = _2504;\n        if (_2504 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2479.x > 1.5)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        vec3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2533 = (_2475 + 2) + (face * 6);\n    int param_6 = _2533;\n    int param_7 = _2533 + 1;\n    int param_8 = _2533 + 3;\n    vec4 _2547 = fa_light_texel(param_8);\n    int param_9 = _2533 + 4;\n    vec4 _2552 = fa_light_texel(param_9);\n    int param_10 = _2533 + 5;\n    vec4 _2557 = fa_light_texel(param_10);\n    float _2569 = _2557.x * max(dot(_2547, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2574 = clamp(dot(n, l), 0.0, 1.0);\n    float _2597 = clamp(dot(n, _2547.xyz), -1.0, 1.0);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2621 = min(sqrt(1.0 - (_2597 * _2597)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2547, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2624 = _2484.y;\n    float _2626;\n    if (_2624 > 0.0)\n    {\n        _2626 = _2624;\n    }\n    else\n    {\n        _2626 = 1.5 * _2569;\n    }\n    vec4 _2646 = vec4(world + (n * (_2626 * sqrt(1.0 - (_2574 * _2574)))), 1.0);\n    float _2650 = dot(_2547, _2646);\n    float _2653 = _2557.y;\n    if (_2650 < _2653)\n    {\n        return 1.0;\n    }\n    vec2 _2668 = vec2(dot(fa_light_texel(param_6), _2646), dot(fa_light_texel(param_7), _2646)) / vec2(_2650);\n    float _2670 = _2668.x;\n    bool _2673 = _2670 < _2552.x;\n    bool _2682;\n    if (!_2673)\n    {\n        _2682 = _2670 > _2552.z;\n    }\n    else\n    {\n        _2682 = _2673;\n    }\n    bool _2691;\n    if (!_2682)\n    {\n        _2691 = _2668.y < _2552.y;\n    }\n    else\n    {\n        _2691 = _2682;\n    }\n    bool _2700;\n    if (!_2691)\n    {\n        _2700 = _2668.y > _2552.w;\n    }\n    else\n    {\n        _2700 = _2691;\n    }\n    if (_2700)\n    {\n        return 1.0;\n    }\n    float _2706 = _2484.x;\n    float _2708;\n    if (_2706 > 0.0)\n    {\n        _2708 = _2706;\n    }\n    else\n    {\n        _2708 = 1.5 * _2569;\n    }\n    vec2 param_13 = _2668;\n    vec4 param_14 = _2552;\n    float param_15 = _2650 - (_2708 * (1.0 + (0.5 * _2621)));\n    float param_16 = _2569;\n    float param_17 = 1.0;\n    float param_18 = _2557.z * 0.25;\n    float param_19 = (_2569 * min(_2621, 3.0)) * 0.5;\n    vec3 param_20 = vec3(1.0, _2653, _2557.z);\n    int param_21 = int(_2479.z + 0.5);\n    float param_22 = _2479.w;\n    return mix(1.0, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3100 = fa_lm.z > 0.5;\n    bool _3106;\n    if (_3100)\n    {\n        int param = li;\n        _3106 = fa_light_baked(param);\n    }\n    else\n    {\n        _3106 = _3100;\n    }\n    if (_3106)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3130 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _4131 = _3130.color;\n    float _4133 = _3130.shadow;\n    if ((_3130.type == 0) && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3130.direction;\n        float _3144 = fa_shadow_factor(param_5, param_6);\n        _4133 = _3144;\n        _4131 *= _3144;\n    }\n    else\n    {\n        bool _3155 = _3130.type != 0;\n        bool _3161;\n        if (_3155)\n        {\n            _3161 = _3130.attenuation > 0.0;\n        }\n        else\n        {\n            _3161 = _3155;\n        }\n        if (_3161)\n        {\n            int param_7 = li;\n            vec3 param_8 = world_pos;\n            vec3 param_9 = gn;\n            vec3 param_10 = _3130.direction;\n            float _3173 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _4133 = _3173;\n            _4131 *= _3173;\n        }\n    }\n    return LightSample(_3130.direction, _4131, _3130.attenuation, _4133, _3130._distance, _3130.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2957 = int(fa_shadows[25].x + 0.5);\n    float _2967 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2972 = _2957 > 0;\n    bool _2981;\n    if (_2972)\n    {\n        int param = _2957 - 1;\n        _2981 = _2967 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2981 = _2972;\n    }\n    if (_2981)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2987 = _2957 > 1;\n        bool _2994;\n        if (_2987)\n        {\n            _2994 = _2967 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2994 = _2987;\n        }\n        if (_2994)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3000 = _2957 > 2;\n        bool _3007;\n        if (_3000)\n        {\n            _3007 = _2967 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3007 = _3000;\n        }\n        if (_3007)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3013 = _2957 > 3;\n        bool _3020;\n        if (_3013)\n        {\n            _3020 = _2967 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3020 = _3013;\n        }\n        if (_3020)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3972 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3972 = -_3972;\n    }\n    vec3 _3556 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3972, fa_world_tangent, fa_uv, fa_vertex_color, _3556, gl_FrontFacing);\n    Surface _3564 = fa_standard_surface(param_1);\n    vec3 _4003 = _3564.albedo;\n    float _4004 = _3564.alpha;\n    vec3 _4005 = _3564.normal;\n    float _4006 = _3564.metallic;\n    float _4007 = _3564.roughness;\n    float _4008 = _3564.occlusion;\n    vec3 _4009 = _3564.emission;\n    float _4010 = _3564.clearcoat;\n    float _4011 = _3564.clearcoat_roughness;\n    vec3 _4012 = _3564.sheen_color;\n    float _4013 = _3564.sheen_roughness;\n    float _4014 = _3564.anisotropy;\n    float _4015 = _3564.anisotropy_rotation;\n    float _4016 = _3564.specular;\n    float _4017 = _3564.ior;\n    vec3 _4018 = _3564.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3972, fa_world_tangent, fa_uv, fa_vertex_color, _3556, gl_FrontFacing);\n    Surface param_3 = _3564;\n    surface(param_2, param_3);\n    _4003 = param_3.albedo;\n    _4004 = param_3.alpha;\n    _4005 = param_3.normal;\n    _4006 = param_3.metallic;\n    _4007 = param_3.roughness;\n    _4008 = param_3.occlusion;\n    _4009 = param_3.emission;\n    _4010 = param_3.clearcoat;\n    _4011 = param_3.clearcoat_roughness;\n    _4012 = param_3.sheen_color;\n    _4013 = param_3.sheen_roughness;\n    _4014 = param_3.anisotropy;\n    _4015 = param_3.anisotropy_rotation;\n    _4016 = param_3.specular;\n    _4017 = param_3.ior;\n    _4018 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _3972;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4003 = param_6;\n    _4005 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4003;\n    }\n    else\n    {\n        vec3 _3602 = _4005;\n        vec3 _3603 = normalize(_3602);\n        _4005 = _3603;\n        vec3 param_8 = _3603;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _4003) * _4008;\n        int _3622 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3622; ln++)\n        {\n            int param_9 = ln;\n            int _3635 = fa_cl_light(param_9);\n            bool _3638 = fa_lm.z > 0.5;\n            bool _3644;\n            if (_3638)\n            {\n                int param_10 = _3635;\n                _3644 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _3644 = _3638;\n            }\n            if (_3644)\n            {\n                continue;\n            }\n            int param_11 = _3635;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _3972;\n            LightSample _3656 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _3972, fa_world_tangent, fa_uv, fa_vertex_color, _3556, gl_FrontFacing);\n            Surface param_15 = Surface(_4003, _4004, _4005, _4006, _4007, _4008, _4009, _4010, _4011, _4012, _4013, _4014, _4015, _4016, _4017, _4018);\n            LightSample param_16 = _3656;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _3671 = result;\n    vec3 _3672 = _3671 + _4009;\n    result = _3672;\n    vec3 param_17 = _3672;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _3681 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3688;\n    if (!_3681)\n    {\n        _3688 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3688 = _3681;\n    }\n    if (_3688)\n    {\n        vec3 _3697 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3703 = dot(_3697, fa_mesh_fs_params[9].xyz);\n        bool _3707 = fa_mesh_fs_params[9].w > 0.5;\n        float _3708;\n        if (_3707)\n        {\n            _3708 = _3703;\n        }\n        else\n        {\n            _3708 = length(_3697);\n        }\n        float _3720 = _3708 - fa_mesh_fs_params[8].x;\n        if (_3720 > 0.0)\n        {\n            float _3729 = fa_mesh_fs_params[7].w * _3720;\n            float tau = _3729 * _3729;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3745;\n                if (_3707)\n                {\n                    _3745 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3703);\n                }\n                else\n                {\n                    _3745 = fa_mesh_fs_params[0].y;\n                }\n                float _3766 = mix(_3745, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3708, 0.0, 1.0));\n                float _3770 = fa_world_pos.y - _3766;\n                float _3775 = _3766 - fa_mesh_fs_params[8].z;\n                float _3780 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3783 = _3775 <= 0.0;\n                bool _3784 = !_3783;\n                bool _3790;\n                if (_3784)\n                {\n                    _3790 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3790 = _3783;\n                }\n                float _3791;\n                if (_3790)\n                {\n                    _3791 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3791 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3775, 80.0));\n                }\n                bool _3818;\n                if (_3784)\n                {\n                    _3818 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3818 = _3783;\n                }\n                float _3819;\n                if (_3818)\n                {\n                    _3819 = fa_mesh_fs_params[8].y * _3775;\n                }\n                else\n                {\n                    _3819 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3775, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3844 = _3780 <= 0.0;\n                bool _3851;\n                if (!_3844)\n                {\n                    _3851 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3851 = _3844;\n                }\n                float _3852;\n                if (_3851)\n                {\n                    _3852 = fa_mesh_fs_params[8].y * _3780;\n                }\n                else\n                {\n                    _3852 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3780, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3879;\n                if (abs(_3770) < 0.001000000047497451305389404296875)\n                {\n                    _3879 = _3791;\n                }\n                else\n                {\n                    _3879 = (_3852 - _3819) / _3770;\n                }\n                tau += (_3720 * max(_3879, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4004);\n}\n\n",
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
            "inst_name": "_314",
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
            "inst_name": "_2011",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _785 = base_t;\n    _785.x = _225.x;\n    _785.y = _225.y;\n    _785.z = _225.z;\n    base_t = _785;\n    vec4 _241 = (_785 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _748 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _793 = _279;\n        _793.x = _284.x;\n        _793.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _796 = mrt;\n    _796.x = _313.x;\n    _796.y = _313.y;\n    _796.z = _313.z;\n    mrt = _796;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _753 = fa_mesh_fs_params[20].x;\n    float _754 = fa_mesh_fs_params[20].y;\n    float _757 = fa_mesh_fs_params[20].z;\n    float _756 = fa_mesh_fs_params[21].w;\n    float _759 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _753 *= _355.y;\n            _754 *= _355.z;\n            _756 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _748, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _753, _754, fa_mesh_fs_params[21].xyz, _756, _757, fa_mesh_fs_params[20].w, _759, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _659 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _785 = base_t;\n    _785.x = _225.x;\n    _785.y = _225.y;\n    _785.z = _225.z;\n    base_t = _785;\n    vec4 _241 = (_785 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _748 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _793 = _279;\n        _793.x = _284.x;\n        _793.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _796 = mrt;\n    _796.x = _313.x;\n    _796.y = _313.y;\n    _796.z = _313.z;\n    mrt = _796;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _753 = fa_mesh_fs_params[20].x;\n    float _754 = fa_mesh_fs_params[20].y;\n    float _757 = fa_mesh_fs_params[20].z;\n    float _756 = fa_mesh_fs_params[21].w;\n    float _759 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _753 *= _355.y;\n            _754 *= _355.z;\n            _756 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _748, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _753, _754, fa_mesh_fs_params[21].xyz, _756, _757, fa_mesh_fs_params[20].w, _759, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _659 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
