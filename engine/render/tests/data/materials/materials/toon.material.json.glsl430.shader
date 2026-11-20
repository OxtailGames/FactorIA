{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "fc5698cd941e0af057040ef4c307a7106b1e2971cc74f7501935817daedb7ce8",
  "slang": "glsl430",
  "params": [
    "dark"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_270, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1292 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1299;\n    if (!_1292)\n    {\n        _1299 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1299 = _1292;\n    }\n    bool _1307;\n    if (!_1299)\n    {\n        _1307 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1307 = _1299;\n    }\n    bool _1314;\n    if (!_1307)\n    {\n        _1314 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1314 = _1307;\n    }\n    bool _1321;\n    if (!_1314)\n    {\n        _1321 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1321 = _1314;\n    }\n    if (_1321)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1331 = vec4(world_pos, 1.0);\n    float _1337 = dot(fa_mesh_fs_params[16], _1331);\n    if (!(_1337 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1359 = vec2(dot(fa_mesh_fs_params[14], _1331), dot(fa_mesh_fs_params[15], _1331)) / vec2(_1337);\n    int _1363 = int(fa_mesh_fs_params[18].x);\n    int _1367 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1367) + clamp(int(floor(((_1359.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1367 - 1)) * _1363)) + clamp(int(floor(((_1359.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1363 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1443 = fa_cluster_texel(param);\n    return ivec2(int(_1443.x), int(_1443.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3083 = fa_cluster_lookup(param);\n    fa_cl_slot = _3083.x;\n    fa_cl_local = _3083.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3258 = fa_linear_to_srgb(param);\n        c = _3258;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3266 = fa_srgb_to_linear(param_1);\n            c = _3266;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _246;\n    if (i.front_facing)\n    {\n        _246 = i.world_normal;\n    }\n    else\n    {\n        _246 = -i.world_normal;\n    }\n    vec3 _270 = normalize(i.world_tangent.xyz - (_246 * dot(_246, i.world_tangent.xyz)));\n    vec3 _298 = normalize(((_270 * m.x) + ((cross(_246, _270) * i.world_tangent.w) * m.y)) + (_246 * m.z));\n    vec3 _301;\n    if (i.front_facing)\n    {\n        _301 = _298;\n    }\n    else\n    {\n        _301 = -_298;\n    }\n    return _301;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3297 = fa_tex_fix(param_2, param_3);\n    vec4 _4322 = base_t;\n    _4322.x = _3297.x;\n    _4322.y = _3297.y;\n    _4322.z = _3297.z;\n    base_t = _4322;\n    vec4 _3311 = (_4322 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4187 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3343 = fa_tex_fix(param_6, param_7);\n        vec3 _3346 = (_3343 * 2.0) - vec3(1.0);\n        vec2 _3351 = _3346.xy * fa_mesh_fs_params[6].x;\n        vec3 _4330 = _3346;\n        _4330.x = _3351.x;\n        _4330.y = _3351.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4330;\n        _4187 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3379 = fa_tex_fix(param_12, param_13);\n    vec4 _4333 = mrt;\n    _4333.x = _3379.x;\n    _4333.y = _3379.y;\n    _4333.z = _3379.z;\n    mrt = _4333;\n    vec4 _3407 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3407.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3418 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3448 = fa_tex_fix(param_20, param_21);\n    float _4192 = fa_mesh_fs_params[20].x;\n    float _4193 = fa_mesh_fs_params[20].y;\n    float _4196 = fa_mesh_fs_params[20].z;\n    float _4195 = fa_mesh_fs_params[21].w;\n    float _4198 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4192 *= _3418.y;\n            _4193 *= _3418.z;\n            _4195 *= _3407.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4196 *= mrt.x;\n            _4198 *= mrt.w;\n        }\n    }\n    return Surface(_3311.xyz, _3311.w, _4187, clamp(fa_mesh_fs_params[5].x * _3379.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3379.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3418.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3448), _4192, _4193, fa_mesh_fs_params[21].xyz, _4195, _4196, fa_mesh_fs_params[20].w, _4198, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1523 = rect.zw - rect.xy;\n    vec2 _1527 = _1523 * atlas;\n    vec2 _1531 = ddx * _1527;\n    vec2 _1535 = ddy * _1527;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1523), clamp(0.5 * log2(max(max(dot(_1531, _1531), dot(_1535, _1535)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1568 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1575;\n    if (!_1568)\n    {\n        _1575 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1575 = _1568;\n    }\n    if (_1575)\n    {\n        return;\n    }\n    vec3 _1581 = dFdx(world_pos);\n    vec3 _1584 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1588 = fa_cluster_texel(param);\n    int _1592 = int(_1588.w);\n    if (_1592 < 1)\n    {\n        return;\n    }\n    int _1602 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1602;\n    vec4 _1606 = fa_light_texel(param_1);\n    vec2 _1609 = _1606.yz;\n    int _1613 = int(_1606.w);\n    int param_2 = _1602 + 1;\n    vec4 _1618 = fa_light_texel(param_2);\n    float _1619 = _1618.x;\n    int _1625 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1629 = int(_1588.z);\n    vec3 _1894;\n    for (int k = 0; k < _1592; k++)\n    {\n        int _1642 = _1629 + k;\n        int param_3 = _1613 + (_1642 >> 2);\n        int _1659 = (_1602 + 2) + (int(fa_light_texel(param_3)[_1642 & 3]) * 7);\n        int param_4 = _1659 + 6;\n        vec4 _1664 = fa_light_texel(param_4);\n        if (((int(_1664.w + 0.5) >> _1625) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1659;\n        vec4 _1679 = fa_light_texel(param_5);\n        int param_6 = _1659 + 1;\n        vec4 _1684 = fa_light_texel(param_6);\n        int param_7 = _1659 + 2;\n        vec4 _1689 = fa_light_texel(param_7);\n        vec3 _1692 = _1679.xyz;\n        float _1697 = dot(_1692, world_pos) + _1679.w;\n        vec3 _1699 = _1684.xyz;\n        float _1704 = dot(_1699, world_pos) + _1684.w;\n        vec3 _1706 = _1689.xyz;\n        float _1711 = dot(_1706, world_pos) + _1689.w;\n        bool _1716 = abs(_1697) > 0.5;\n        bool _1724;\n        if (!_1716)\n        {\n            _1724 = abs(_1704) > 0.5;\n        }\n        else\n        {\n            _1724 = _1716;\n        }\n        bool _1732;\n        if (!_1724)\n        {\n            _1732 = abs(_1711) > 0.5;\n        }\n        else\n        {\n            _1732 = _1724;\n        }\n        if (_1732)\n        {\n            continue;\n        }\n        float _1747 = clamp(dot(geo_normal, normalize(_1706)) * _1664.z, 0.0, 1.0);\n        if (_1747 <= 0.0)\n        {\n            continue;\n        }\n        float _1767 = (clamp((0.5 - abs(_1711)) * 10.0, 0.0, 1.0) * _1747) * _1664.x;\n        vec2 _1775 = vec2(_1697 + 0.5, 0.5 - _1704);\n        vec2 _1785 = vec2(dot(_1692, _1581), dot(_1699, _1581));\n        vec2 _1795 = vec2(dot(_1692, _1584), dot(_1699, _1584));\n        int param_8 = _1659 + 5;\n        vec4 _1800 = fa_light_texel(param_8);\n        int param_9 = _1659 + 3;\n        vec4 _1805 = fa_light_texel(param_9);\n        int param_10 = _1659 + 4;\n        vec4 _1810 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1800.xyz;\n        bool _1820 = _1805.z > _1805.x;\n        if (_1820)\n        {\n            vec4 param_11 = _1805;\n            vec2 param_12 = _1775;\n            vec2 param_13 = _1609;\n            vec2 param_14 = _1785;\n            vec2 param_15 = _1795;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1619 > 0.5) && (_1619 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1846 = fa_dc_to_linear(param_16);\n                vec4 _4267 = tx;\n                _4267.x = _1846.x;\n                _4267.y = _1846.y;\n                _4267.z = _1846.z;\n                tx = _4267;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1767 * tex_a) * _1800.w, 0.0, 1.0)));\n        if (_1810.z > _1810.x)\n        {\n            vec4 param_17 = _1810;\n            vec2 param_18 = _1775;\n            vec2 param_19 = _1609;\n            vec2 param_20 = _1785;\n            vec2 param_21 = _1795;\n            vec4 _1890 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1619 > 1.5)\n            {\n                vec3 param_22 = _1890.xyz;\n                vec3 _1900 = fa_dc_to_srgb(param_22);\n                _1894 = _1900;\n            }\n            else\n            {\n                _1894 = _1890.xyz;\n            }\n            vec3 _1909 = (_1894 * 2.0) - vec3(1.0);\n            vec2 _1914 = _1909.xy * _1664.y;\n            vec3 _1936 = (normalize(_1692) * _1914.x) + (normalize(_1699) * _1914.y);\n            vec3 _1939 = normalize(normal);\n            normal = normalize(mix(_1939, normalize((_1939 * max(_1909.z, 0.0500000007450580596923828125)) + (_1936 - (_1939 * dot(_1939, _1936)))), vec3(clamp(_1767 * (_1820 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _542 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _555 = (c - (ru * hx)) - p;\n        vec3 _561 = ru * (2.0 * hx);\n        float _567 = max(dot(_561, _561), 9.9999999392252902907785028219223e-09);\n        float _571 = dot(_555, _561);\n        float t = clamp((-_571) / _567, 0.0, 1.0);\n        if (_542)\n        {\n            float _586 = dot(r, _561);\n            float _592 = _567 - (_586 * _586);\n            if (abs(_592) > (9.9999997473787516355514526367188e-06 * _567))\n            {\n                t = clamp(((dot(r, _555) * _586) - _571) / _592, 0.0, 1.0);\n            }\n        }\n        return (p + _555) + (_561 * t);\n    }\n    vec3 q = p;\n    float _624 = dot(r, axis);\n    bool _632;\n    if (_542)\n    {\n        _632 = abs(_624) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _632 = _542;\n    }\n    if (_632)\n    {\n        float _642 = dot(c - p, axis) / _624;\n        if (_642 > 0.0)\n        {\n            q = p + (r * _642);\n        }\n    }\n    vec3 _655 = q - c;\n    vec2 xy = vec2(dot(_655, ru), dot(_655, uu));\n    if (shape > 0.5)\n    {\n        float _670 = length(xy);\n        if (_670 > hx)\n        {\n            xy *= (hx / _670);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _463 = abs(d);\n    float _465 = _463.x;\n    float _467 = _463.y;\n    bool _468 = _465 >= _467;\n    bool _476;\n    if (_468)\n    {\n        _476 = _465 >= _463.z;\n    }\n    else\n    {\n        _476 = _468;\n    }\n    int _477;\n    if (_476)\n    {\n        _477 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _490;\n        if (_467 >= _463.z)\n        {\n            _490 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _490 = (d.z > 0.0) ? 4 : 5;\n        }\n        _477 = _490;\n    }\n    return _477;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _416 = dot(d, right);\n    float _420 = dot(d, up);\n    float _431;\n    if (((_416 * _416) + (_420 * _420)) > 1.0000000133514319600180897396058e-10)\n    {\n        _431 = atan(_420, _416) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _431 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_431 - floor(_431)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _708 = fa_light_base(param);\n    bool _712 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _708;\n    vec4 _716 = fa_light_texel(param_1);\n    int param_2 = _708 + 1;\n    vec4 _721 = fa_light_texel(param_2);\n    float _724 = _721.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _736 = _712 && (_724 > 2.5);\n    fa_light_is_area = _736;\n    bool _738 = _724 < 0.5;\n    vec3 l;\n    if (_738)\n    {\n        l = normalize(_716.xyz);\n        if (_712)\n        {\n            int param_3 = _708 + 6;\n            vec4 _752 = fa_light_texel(param_3);\n            if (_752.z > 0.5)\n            {\n                int param_4 = _708 + 4;\n                vec4 _762 = fa_light_texel(param_4);\n                int param_5 = _708 + 5;\n                vec4 _767 = fa_light_texel(param_5);\n                vec2 param_6 = _752.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _762.xyz) * _762.w, (-dot(world_pos, _767.xyz)) * _767.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _797 = _716.xyz;\n        vec3 _799 = _797 - world_pos;\n        vec3 to_light = _799;\n        float _802 = length(_799);\n        float reach = _802;\n        bool front = true;\n        if (_736)\n        {\n            int param_8 = _708 + 7;\n            reach = max(_802 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _708 + 4;\n            vec4 _826 = fa_light_texel(param_9);\n            int param_10 = _708 + 5;\n            vec4 _831 = fa_light_texel(param_10);\n            int param_11 = _708 + 6;\n            vec4 _836 = fa_light_texel(param_11);\n            float _837 = _836.w;\n            int param_12 = _708 + 2;\n            vec3 _844 = normalize(fa_light_texel(param_12).xyz);\n            bool _846 = _837 > 1.5;\n            bool _854;\n            if (!_846)\n            {\n                _854 = dot(_844, to_light) < 0.0;\n            }\n            else\n            {\n                _854 = _846;\n            }\n            front = _854;\n            vec3 r = vec3(0.0);\n            vec3 _863 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _867 = dot(n, n) > 0.5;\n            bool _875;\n            if (_867)\n            {\n                _875 = dot(_863, _863) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _875 = _867;\n            }\n            if (_875)\n            {\n                r = reflect(-normalize(_863), normalize(n));\n            }\n            vec3 param_13 = _797;\n            vec3 param_14 = _844;\n            vec3 param_15 = _826.xyz;\n            vec3 param_16 = _831.xyz;\n            float param_17 = _826.w;\n            float param_18 = _831.w;\n            float param_19 = _837;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _911 = length(to_light);\n        dist = _911;\n        l = to_light / vec3(max(_911, 9.9999997473787516355514526367188e-05));\n        float _925 = reach / max(_716.w, 0.001000000047497451305389404296875);\n        float _931 = clamp(1.0 - (_925 * _925), 0.0, 1.0);\n        float _933;\n        if (front)\n        {\n            _933 = _931 * _931;\n        }\n        else\n        {\n            _933 = 0.0;\n        }\n        atten = _933;\n        bool _944 = _724 < 2.5;\n        if ((_724 > 1.5) && _944)\n        {\n            int param_22 = _708 + 2;\n            vec4 _952 = fa_light_texel(param_22);\n            float _962 = _952.w;\n            int param_23 = _708 + 3;\n            vec4 _967 = fa_light_texel(param_23);\n            float _968 = _967.x;\n            float cos_inner = _968;\n            if (_968 > 1.5)\n            {\n                cos_inner = mix(_962, 1.0, 0.25);\n            }\n            atten *= smoothstep(_962, cos_inner, dot(-l, normalize(_952.xyz)));\n        }\n        if (_712 && (_724 < 1.5))\n        {\n            int param_24 = _708 + 6;\n            vec4 _992 = fa_light_texel(param_24);\n            if (_992.z > 0.5)\n            {\n                vec3 _1000 = -to_light;\n                int param_25 = _708 + 4;\n                int param_26 = _708 + 5;\n                vec3 _1014 = fa_light_texel(param_25).xyz;\n                vec3 _1018 = fa_light_texel(param_26).xyz;\n                vec3 _1027 = vec3(dot(_1000, _1014), dot(_1000, _1018), dot(_1000, cross(_1014, _1018)));\n                vec3 param_27 = _1027;\n                int _1031 = fa_cube_face(param_27);\n                int param_28 = _1031;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1058 = vec2(dot(_1027, cross(param_29, param_30)), dot(_1027, param_30)) / vec2(max(dot(_1027, param_29), 9.9999997473787516355514526367188e-05));\n                int _1062 = _1031 / 3;\n                vec2 param_31 = _992.xy + (vec2(float(_1031 - (_1062 * 3)), float(_1062)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1058.x), 0.5 - (0.5 * _1058.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _708 + 7;\n            vec4 _1092 = fa_light_texel(param_33);\n            if (_1092.z > 0.5)\n            {\n                int param_34 = _708 + 2;\n                int param_35 = _708 + 4;\n                int param_36 = _708 + 5;\n                vec2 param_37 = _1092.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_712 && _944)\n            {\n                int param_42 = _708 + 6;\n                vec4 _1139 = fa_light_texel(param_42);\n                int param_43 = _708 + 7;\n                vec4 _1144 = fa_light_texel(param_43);\n                bool _1147 = _1139.z > 0.5;\n                bool _1154;\n                if (!_1147)\n                {\n                    _1154 = _1144.z > 0.5;\n                }\n                else\n                {\n                    _1154 = _1147;\n                }\n                if (_1154)\n                {\n                    int param_44 = _708 + 2;\n                    vec4 _1161 = fa_light_texel(param_44);\n                    vec3 _1165 = normalize(_1161.xyz);\n                    int param_45 = _708 + 4;\n                    vec4 _1170 = fa_light_texel(param_45);\n                    int param_46 = _708 + 5;\n                    vec4 _1175 = fa_light_texel(param_46);\n                    if (_1147)\n                    {\n                        vec3 _1183 = -to_light;\n                        float _1190 = _1161.w;\n                        float _1206 = 0.5 / max(dot(_1183, _1165) * (sqrt(max(1.0 - (_1190 * _1190), 0.0)) / max(_1190, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1139.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1183, _1170.xyz) * _1206), 0.5 - (dot(_1183, _1175.xyz) * _1206));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1144.z > 0.5)\n                    {\n                        vec2 param_49 = _1144.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1165;\n                        vec3 param_52 = _1170.xyz;\n                        vec3 param_53 = _1175.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _4141 = _721.xyz * atten;\n    if (_712)\n    {\n        _4141 *= fa_light_tint;\n    }\n    int _1274;\n    if (_738)\n    {\n        _1274 = 0;\n    }\n    else\n    {\n        _1274 = ((_724 > 1.5) && (_724 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4141, atten, 1.0, dist, _1274);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2011;\n    if (i == 0)\n    {\n        _2011 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2027;\n        if (i == 1)\n        {\n            _2027 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2035;\n            if (i == 2)\n            {\n                _2035 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2035 = fa_shadows[24].w;\n            }\n            _2027 = _2035;\n        }\n        _2011 = _2027;\n    }\n    return _2011;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2068 = fa_shadow_depth(param, param_1);\n    float _2072;\n    if (conv.x < 0.5)\n    {\n        _2072 = _2068;\n    }\n    else\n    {\n        _2072 = (conv.y * conv.z) / (conv.z - (_2068 * (conv.z - conv.y)));\n    }\n    return _2072;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1999 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1999), sin(_1999)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2118 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2127;\n        if (k < 0.0)\n        {\n            _2127 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2127 = k;\n        }\n        float _2147 = clamp((_2127 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2118;\n            vec2 _2166 = fa_shadow_vogel(param_3, param_4, param_5) * _2147;\n            vec2 param_6 = uv + (_2166 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2178 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2178 < (zr - (length(_2166) * plane)))\n            {\n                sum += _2178;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2204 = sum / cnt;\n        float _2214;\n        if (k < 0.0)\n        {\n            _2214 = (-k) / max(_2204, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2214 = k;\n        }\n        radius = clamp(((max(zr - _2204, 0.0) * unit) * _2214) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2236 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2236; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2236;\n        float param_11 = _2118;\n        vec2 _2255 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2255 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2255) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2236);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2297 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2302 = clamp(dot(n, l), 0.0, 1.0);\n    float _2308 = sqrt(1.0 - (_2302 * _2302));\n    float _2315 = min(_2308 / max(_2302, 0.20000000298023223876953125), 4.0);\n    float _2320;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2320 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2320 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2345 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2320 * _2308)), 1.0);\n    float _2352 = _2345.x;\n    bool _2355 = _2352 < fa_shadows[ci * 1 + 16].x;\n    bool _2364;\n    if (!_2355)\n    {\n        _2364 = _2352 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2364 = _2355;\n    }\n    bool _2373;\n    if (!_2364)\n    {\n        _2373 = _2345.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2373 = _2364;\n    }\n    bool _2382;\n    if (!_2373)\n    {\n        _2382 = _2345.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2382 = _2373;\n    }\n    bool _2389;\n    if (!_2382)\n    {\n        _2389 = _2345.z > 1.0;\n    }\n    else\n    {\n        _2389 = _2382;\n    }\n    if (_2389)\n    {\n        return -1.0;\n    }\n    float _2397;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2397 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2397 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2345.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2345.z - ((_2397 * (1.0 + (0.5 * _2315))) / _2297);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2297;\n    float param_5 = _2297 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2315, 3.0)) * 0.5) / _2297;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2785 = int(fa_shadows[25].x + 0.5);\n    if (_2785 < 1)\n    {\n        return 1.0;\n    }\n    float _2800 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2785 - 1;\n    if (_2800 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2812 = _2785 > 1;\n    bool _2819;\n    if (_2812)\n    {\n        _2819 = _2800 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2819 = _2812;\n    }\n    if (_2819)\n    {\n        ci = 1;\n    }\n    bool _2823 = _2785 > 2;\n    bool _2830;\n    if (_2823)\n    {\n        _2830 = _2800 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2830 = _2823;\n    }\n    if (_2830)\n    {\n        ci = 2;\n    }\n    bool _2834 = _2785 > 3;\n    bool _2841;\n    if (_2834)\n    {\n        _2841 = _2800 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2841 = _2834;\n    }\n    if (_2841)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2785)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2867 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2867;\n        if (_2867 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2892;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2892 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2892 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2911 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2892, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2922 = clamp((_2800 - (fa_shadow_split_at(param_7) - _2911)) / _2911, 0.0, 1.0);\n        if (_2922 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2785)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2943 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2943;\n                if (_2943 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2922);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _2455 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2462;\n    if (!_2455)\n    {\n        _2462 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2462 = _2455;\n    }\n    if (_2462)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2475 = fa_light_texel(param);\n    float _2476 = _2475.x;\n    if (_2476 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2485 = int(_2476 + 0.5);\n    int param_1 = _2485;\n    vec4 _2489 = fa_light_texel(param_1);\n    int param_2 = _2485 + 1;\n    vec4 _2494 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2497 = _2489.y;\n    if (_2497 > 0.0)\n    {\n        float _2514 = 1.0 - smoothstep(0.75 * _2497, _2497, length(world - fa_shadows[27].xyz));\n        fade = _2514;\n        if (_2514 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2489.x > 1.5)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        vec3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2543 = (_2485 + 2) + (face * 6);\n    int param_6 = _2543;\n    int param_7 = _2543 + 1;\n    int param_8 = _2543 + 3;\n    vec4 _2557 = fa_light_texel(param_8);\n    int param_9 = _2543 + 4;\n    vec4 _2562 = fa_light_texel(param_9);\n    int param_10 = _2543 + 5;\n    vec4 _2567 = fa_light_texel(param_10);\n    float _2579 = _2567.x * max(dot(_2557, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2584 = clamp(dot(n, l), 0.0, 1.0);\n    float _2607 = clamp(dot(n, _2557.xyz), -1.0, 1.0);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2631 = min(sqrt(1.0 - (_2607 * _2607)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2557, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2634 = _2494.y;\n    float _2636;\n    if (_2634 > 0.0)\n    {\n        _2636 = _2634;\n    }\n    else\n    {\n        _2636 = 1.5 * _2579;\n    }\n    vec4 _2656 = vec4(world + (n * (_2636 * sqrt(1.0 - (_2584 * _2584)))), 1.0);\n    float _2660 = dot(_2557, _2656);\n    float _2663 = _2567.y;\n    if (_2660 < _2663)\n    {\n        return 1.0;\n    }\n    vec2 _2678 = vec2(dot(fa_light_texel(param_6), _2656), dot(fa_light_texel(param_7), _2656)) / vec2(_2660);\n    float _2680 = _2678.x;\n    bool _2683 = _2680 < _2562.x;\n    bool _2692;\n    if (!_2683)\n    {\n        _2692 = _2680 > _2562.z;\n    }\n    else\n    {\n        _2692 = _2683;\n    }\n    bool _2701;\n    if (!_2692)\n    {\n        _2701 = _2678.y < _2562.y;\n    }\n    else\n    {\n        _2701 = _2692;\n    }\n    bool _2710;\n    if (!_2701)\n    {\n        _2710 = _2678.y > _2562.w;\n    }\n    else\n    {\n        _2710 = _2701;\n    }\n    if (_2710)\n    {\n        return 1.0;\n    }\n    float _2716 = _2494.x;\n    float _2718;\n    if (_2716 > 0.0)\n    {\n        _2718 = _2716;\n    }\n    else\n    {\n        _2718 = 1.5 * _2579;\n    }\n    vec2 param_13 = _2678;\n    vec4 param_14 = _2562;\n    float param_15 = _2660 - (_2718 * (1.0 + (0.5 * _2631)));\n    float param_16 = _2579;\n    float param_17 = 1.0;\n    float param_18 = _2567.z * 0.25;\n    float param_19 = (_2579 * min(_2631, 3.0)) * 0.5;\n    vec3 param_20 = vec3(1.0, _2663, _2567.z);\n    int param_21 = int(_2489.z + 0.5);\n    float param_22 = _2489.w;\n    return mix(1.0, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3110 = fa_lm.z > 0.5;\n    bool _3116;\n    if (_3110)\n    {\n        int param = li;\n        _3116 = fa_light_baked(param);\n    }\n    else\n    {\n        _3116 = _3110;\n    }\n    if (_3116)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3140 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _4167 = _3140.color;\n    float _4169 = _3140.shadow;\n    if ((_3140.type == 0) && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3140.direction;\n        float _3154 = fa_shadow_factor(param_5, param_6);\n        _4169 = _3154;\n        _4167 *= _3154;\n    }\n    else\n    {\n        bool _3165 = _3140.type != 0;\n        bool _3171;\n        if (_3165)\n        {\n            _3171 = _3140.attenuation > 0.0;\n        }\n        else\n        {\n            _3171 = _3165;\n        }\n        if (_3171)\n        {\n            int param_7 = li;\n            vec3 param_8 = world_pos;\n            vec3 param_9 = gn;\n            vec3 param_10 = _3140.direction;\n            float _3183 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _4169 = _3183;\n            _4167 *= _3183;\n        }\n    }\n    return LightSample(_3140.direction, _4167, _3140.attenuation, _4169, _3140._distance, _3140.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _3203;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _3203 = 1.0;\n    }\n    else\n    {\n        _3203 = fa_material[0].x;\n    }\n    return (s.albedo * l.color) * _3203;\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2967 = int(fa_shadows[25].x + 0.5);\n    float _2977 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2982 = _2967 > 0;\n    bool _2991;\n    if (_2982)\n    {\n        int param = _2967 - 1;\n        _2991 = _2977 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2991 = _2982;\n    }\n    if (_2991)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2997 = _2967 > 1;\n        bool _3004;\n        if (_2997)\n        {\n            _3004 = _2977 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3004 = _2997;\n        }\n        if (_3004)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3010 = _2967 > 2;\n        bool _3017;\n        if (_3010)\n        {\n            _3017 = _2977 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3017 = _3010;\n        }\n        if (_3017)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3023 = _2967 > 3;\n        bool _3030;\n        if (_3023)\n        {\n            _3030 = _2977 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3030 = _3023;\n        }\n        if (_3030)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4008 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4008 = -_4008;\n    }\n    vec3 _3592 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4008, fa_world_tangent, fa_uv, fa_vertex_color, _3592, gl_FrontFacing);\n    Surface _3600 = fa_standard_surface(param_1);\n    vec3 _4039 = _3600.albedo;\n    float _4040 = _3600.alpha;\n    vec3 _4041 = _3600.normal;\n    float _4042 = _3600.metallic;\n    float _4043 = _3600.roughness;\n    float _4044 = _3600.occlusion;\n    vec3 _4045 = _3600.emission;\n    float _4046 = _3600.clearcoat;\n    float _4047 = _3600.clearcoat_roughness;\n    vec3 _4048 = _3600.sheen_color;\n    float _4049 = _3600.sheen_roughness;\n    float _4050 = _3600.anisotropy;\n    float _4051 = _3600.anisotropy_rotation;\n    float _4052 = _3600.specular;\n    float _4053 = _3600.ior;\n    vec3 _4054 = _3600.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4008, fa_world_tangent, fa_uv, fa_vertex_color, _3592, gl_FrontFacing);\n    Surface param_3 = _3600;\n    surface(param_2, param_3);\n    _4039 = param_3.albedo;\n    _4040 = param_3.alpha;\n    _4041 = param_3.normal;\n    _4042 = param_3.metallic;\n    _4043 = param_3.roughness;\n    _4044 = param_3.occlusion;\n    _4045 = param_3.emission;\n    _4046 = param_3.clearcoat;\n    _4047 = param_3.clearcoat_roughness;\n    _4048 = param_3.sheen_color;\n    _4049 = param_3.sheen_roughness;\n    _4050 = param_3.anisotropy;\n    _4051 = param_3.anisotropy_rotation;\n    _4052 = param_3.specular;\n    _4053 = param_3.ior;\n    _4054 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4008;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4039 = param_6;\n    _4041 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4039;\n    }\n    else\n    {\n        vec3 _3638 = _4041;\n        vec3 _3639 = normalize(_3638);\n        _4041 = _3639;\n        vec3 param_8 = _3639;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _4039) * _4044;\n        int _3658 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3658; ln++)\n        {\n            int param_9 = ln;\n            int _3671 = fa_cl_light(param_9);\n            bool _3674 = fa_lm.z > 0.5;\n            bool _3680;\n            if (_3674)\n            {\n                int param_10 = _3671;\n                _3680 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _3680 = _3674;\n            }\n            if (_3680)\n            {\n                continue;\n            }\n            int param_11 = _3671;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _4008;\n            LightSample _3692 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _4008, fa_world_tangent, fa_uv, fa_vertex_color, _3592, gl_FrontFacing);\n            Surface param_15 = Surface(_4039, _4040, _4041, _4042, _4043, _4044, _4045, _4046, _4047, _4048, _4049, _4050, _4051, _4052, _4053, _4054);\n            LightSample param_16 = _3692;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _3707 = result;\n    vec3 _3708 = _3707 + _4045;\n    result = _3708;\n    vec3 param_17 = _3708;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _3717 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3724;\n    if (!_3717)\n    {\n        _3724 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3724 = _3717;\n    }\n    if (_3724)\n    {\n        vec3 _3733 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3739 = dot(_3733, fa_mesh_fs_params[9].xyz);\n        bool _3743 = fa_mesh_fs_params[9].w > 0.5;\n        float _3744;\n        if (_3743)\n        {\n            _3744 = _3739;\n        }\n        else\n        {\n            _3744 = length(_3733);\n        }\n        float _3756 = _3744 - fa_mesh_fs_params[8].x;\n        if (_3756 > 0.0)\n        {\n            float _3765 = fa_mesh_fs_params[7].w * _3756;\n            float tau = _3765 * _3765;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3781;\n                if (_3743)\n                {\n                    _3781 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3739);\n                }\n                else\n                {\n                    _3781 = fa_mesh_fs_params[0].y;\n                }\n                float _3802 = mix(_3781, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3744, 0.0, 1.0));\n                float _3806 = fa_world_pos.y - _3802;\n                float _3811 = _3802 - fa_mesh_fs_params[8].z;\n                float _3816 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3819 = _3811 <= 0.0;\n                bool _3820 = !_3819;\n                bool _3826;\n                if (_3820)\n                {\n                    _3826 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3826 = _3819;\n                }\n                float _3827;\n                if (_3826)\n                {\n                    _3827 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3827 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3811, 80.0));\n                }\n                bool _3854;\n                if (_3820)\n                {\n                    _3854 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3854 = _3819;\n                }\n                float _3855;\n                if (_3854)\n                {\n                    _3855 = fa_mesh_fs_params[8].y * _3811;\n                }\n                else\n                {\n                    _3855 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3811, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3880 = _3816 <= 0.0;\n                bool _3887;\n                if (!_3880)\n                {\n                    _3887 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3887 = _3880;\n                }\n                float _3888;\n                if (_3887)\n                {\n                    _3888 = fa_mesh_fs_params[8].y * _3816;\n                }\n                else\n                {\n                    _3888 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3816, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3915;\n                if (abs(_3806) < 0.001000000047497451305389404296875)\n                {\n                    _3915 = _3827;\n                }\n                else\n                {\n                    _3915 = (_3888 - _3855) / _3806;\n                }\n                tau += (_3756 * max(_3915, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4040);\n}\n\n",
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
            "inst_name": "_2021",
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
            "inst_name": "_3209",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_391, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1292 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1299;\n    if (!_1292)\n    {\n        _1299 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1299 = _1292;\n    }\n    bool _1307;\n    if (!_1299)\n    {\n        _1307 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1307 = _1299;\n    }\n    bool _1314;\n    if (!_1307)\n    {\n        _1314 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1314 = _1307;\n    }\n    bool _1321;\n    if (!_1314)\n    {\n        _1321 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1321 = _1314;\n    }\n    if (_1321)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1331 = vec4(world_pos, 1.0);\n    float _1337 = dot(fa_mesh_fs_params[16], _1331);\n    if (!(_1337 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1359 = vec2(dot(fa_mesh_fs_params[14], _1331), dot(fa_mesh_fs_params[15], _1331)) / vec2(_1337);\n    int _1363 = int(fa_mesh_fs_params[18].x);\n    int _1367 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1367) + clamp(int(floor(((_1359.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1367 - 1)) * _1363)) + clamp(int(floor(((_1359.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1363 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1443 = fa_cluster_texel(param);\n    return ivec2(int(_1443.x), int(_1443.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3083 = fa_cluster_lookup(param);\n    fa_cl_slot = _3083.x;\n    fa_cl_local = _3083.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3258 = fa_linear_to_srgb(param);\n        c = _3258;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3266 = fa_srgb_to_linear(param_1);\n            c = _3266;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _246;\n    if (i.front_facing)\n    {\n        _246 = i.world_normal;\n    }\n    else\n    {\n        _246 = -i.world_normal;\n    }\n    vec3 _270 = normalize(i.world_tangent.xyz - (_246 * dot(_246, i.world_tangent.xyz)));\n    vec3 _298 = normalize(((_270 * m.x) + ((cross(_246, _270) * i.world_tangent.w) * m.y)) + (_246 * m.z));\n    vec3 _301;\n    if (i.front_facing)\n    {\n        _301 = _298;\n    }\n    else\n    {\n        _301 = -_298;\n    }\n    return _301;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3297 = fa_tex_fix(param_2, param_3);\n    vec4 _4322 = base_t;\n    _4322.x = _3297.x;\n    _4322.y = _3297.y;\n    _4322.z = _3297.z;\n    base_t = _4322;\n    vec4 _3311 = (_4322 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4187 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3343 = fa_tex_fix(param_6, param_7);\n        vec3 _3346 = (_3343 * 2.0) - vec3(1.0);\n        vec2 _3351 = _3346.xy * fa_mesh_fs_params[6].x;\n        vec3 _4330 = _3346;\n        _4330.x = _3351.x;\n        _4330.y = _3351.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4330;\n        _4187 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3379 = fa_tex_fix(param_12, param_13);\n    vec4 _4333 = mrt;\n    _4333.x = _3379.x;\n    _4333.y = _3379.y;\n    _4333.z = _3379.z;\n    mrt = _4333;\n    vec4 _3407 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3407.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3418 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3448 = fa_tex_fix(param_20, param_21);\n    float _4192 = fa_mesh_fs_params[20].x;\n    float _4193 = fa_mesh_fs_params[20].y;\n    float _4196 = fa_mesh_fs_params[20].z;\n    float _4195 = fa_mesh_fs_params[21].w;\n    float _4198 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4192 *= _3418.y;\n            _4193 *= _3418.z;\n            _4195 *= _3407.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4196 *= mrt.x;\n            _4198 *= mrt.w;\n        }\n    }\n    return Surface(_3311.xyz, _3311.w, _4187, clamp(fa_mesh_fs_params[5].x * _3379.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3379.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3418.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3448), _4192, _4193, fa_mesh_fs_params[21].xyz, _4195, _4196, fa_mesh_fs_params[20].w, _4198, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1523 = rect.zw - rect.xy;\n    vec2 _1527 = _1523 * atlas;\n    vec2 _1531 = ddx * _1527;\n    vec2 _1535 = ddy * _1527;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1523), clamp(0.5 * log2(max(max(dot(_1531, _1531), dot(_1535, _1535)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1568 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1575;\n    if (!_1568)\n    {\n        _1575 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1575 = _1568;\n    }\n    if (_1575)\n    {\n        return;\n    }\n    vec3 _1581 = dFdx(world_pos);\n    vec3 _1584 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1588 = fa_cluster_texel(param);\n    int _1592 = int(_1588.w);\n    if (_1592 < 1)\n    {\n        return;\n    }\n    int _1602 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1602;\n    vec4 _1606 = fa_light_texel(param_1);\n    vec2 _1609 = _1606.yz;\n    int _1613 = int(_1606.w);\n    int param_2 = _1602 + 1;\n    vec4 _1618 = fa_light_texel(param_2);\n    float _1619 = _1618.x;\n    int _1625 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1629 = int(_1588.z);\n    vec3 _1894;\n    for (int k = 0; k < _1592; k++)\n    {\n        int _1642 = _1629 + k;\n        int param_3 = _1613 + (_1642 >> 2);\n        int _1659 = (_1602 + 2) + (int(fa_light_texel(param_3)[_1642 & 3]) * 7);\n        int param_4 = _1659 + 6;\n        vec4 _1664 = fa_light_texel(param_4);\n        if (((int(_1664.w + 0.5) >> _1625) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1659;\n        vec4 _1679 = fa_light_texel(param_5);\n        int param_6 = _1659 + 1;\n        vec4 _1684 = fa_light_texel(param_6);\n        int param_7 = _1659 + 2;\n        vec4 _1689 = fa_light_texel(param_7);\n        vec3 _1692 = _1679.xyz;\n        float _1697 = dot(_1692, world_pos) + _1679.w;\n        vec3 _1699 = _1684.xyz;\n        float _1704 = dot(_1699, world_pos) + _1684.w;\n        vec3 _1706 = _1689.xyz;\n        float _1711 = dot(_1706, world_pos) + _1689.w;\n        bool _1716 = abs(_1697) > 0.5;\n        bool _1724;\n        if (!_1716)\n        {\n            _1724 = abs(_1704) > 0.5;\n        }\n        else\n        {\n            _1724 = _1716;\n        }\n        bool _1732;\n        if (!_1724)\n        {\n            _1732 = abs(_1711) > 0.5;\n        }\n        else\n        {\n            _1732 = _1724;\n        }\n        if (_1732)\n        {\n            continue;\n        }\n        float _1747 = clamp(dot(geo_normal, normalize(_1706)) * _1664.z, 0.0, 1.0);\n        if (_1747 <= 0.0)\n        {\n            continue;\n        }\n        float _1767 = (clamp((0.5 - abs(_1711)) * 10.0, 0.0, 1.0) * _1747) * _1664.x;\n        vec2 _1775 = vec2(_1697 + 0.5, 0.5 - _1704);\n        vec2 _1785 = vec2(dot(_1692, _1581), dot(_1699, _1581));\n        vec2 _1795 = vec2(dot(_1692, _1584), dot(_1699, _1584));\n        int param_8 = _1659 + 5;\n        vec4 _1800 = fa_light_texel(param_8);\n        int param_9 = _1659 + 3;\n        vec4 _1805 = fa_light_texel(param_9);\n        int param_10 = _1659 + 4;\n        vec4 _1810 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1800.xyz;\n        bool _1820 = _1805.z > _1805.x;\n        if (_1820)\n        {\n            vec4 param_11 = _1805;\n            vec2 param_12 = _1775;\n            vec2 param_13 = _1609;\n            vec2 param_14 = _1785;\n            vec2 param_15 = _1795;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1619 > 0.5) && (_1619 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1846 = fa_dc_to_linear(param_16);\n                vec4 _4267 = tx;\n                _4267.x = _1846.x;\n                _4267.y = _1846.y;\n                _4267.z = _1846.z;\n                tx = _4267;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1767 * tex_a) * _1800.w, 0.0, 1.0)));\n        if (_1810.z > _1810.x)\n        {\n            vec4 param_17 = _1810;\n            vec2 param_18 = _1775;\n            vec2 param_19 = _1609;\n            vec2 param_20 = _1785;\n            vec2 param_21 = _1795;\n            vec4 _1890 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1619 > 1.5)\n            {\n                vec3 param_22 = _1890.xyz;\n                vec3 _1900 = fa_dc_to_srgb(param_22);\n                _1894 = _1900;\n            }\n            else\n            {\n                _1894 = _1890.xyz;\n            }\n            vec3 _1909 = (_1894 * 2.0) - vec3(1.0);\n            vec2 _1914 = _1909.xy * _1664.y;\n            vec3 _1936 = (normalize(_1692) * _1914.x) + (normalize(_1699) * _1914.y);\n            vec3 _1939 = normalize(normal);\n            normal = normalize(mix(_1939, normalize((_1939 * max(_1909.z, 0.0500000007450580596923828125)) + (_1936 - (_1939 * dot(_1939, _1936)))), vec3(clamp(_1767 * (_1820 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _542 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _555 = (c - (ru * hx)) - p;\n        vec3 _561 = ru * (2.0 * hx);\n        float _567 = max(dot(_561, _561), 9.9999999392252902907785028219223e-09);\n        float _571 = dot(_555, _561);\n        float t = clamp((-_571) / _567, 0.0, 1.0);\n        if (_542)\n        {\n            float _586 = dot(r, _561);\n            float _592 = _567 - (_586 * _586);\n            if (abs(_592) > (9.9999997473787516355514526367188e-06 * _567))\n            {\n                t = clamp(((dot(r, _555) * _586) - _571) / _592, 0.0, 1.0);\n            }\n        }\n        return (p + _555) + (_561 * t);\n    }\n    vec3 q = p;\n    float _624 = dot(r, axis);\n    bool _632;\n    if (_542)\n    {\n        _632 = abs(_624) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _632 = _542;\n    }\n    if (_632)\n    {\n        float _642 = dot(c - p, axis) / _624;\n        if (_642 > 0.0)\n        {\n            q = p + (r * _642);\n        }\n    }\n    vec3 _655 = q - c;\n    vec2 xy = vec2(dot(_655, ru), dot(_655, uu));\n    if (shape > 0.5)\n    {\n        float _670 = length(xy);\n        if (_670 > hx)\n        {\n            xy *= (hx / _670);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _463 = abs(d);\n    float _465 = _463.x;\n    float _467 = _463.y;\n    bool _468 = _465 >= _467;\n    bool _476;\n    if (_468)\n    {\n        _476 = _465 >= _463.z;\n    }\n    else\n    {\n        _476 = _468;\n    }\n    int _477;\n    if (_476)\n    {\n        _477 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _490;\n        if (_467 >= _463.z)\n        {\n            _490 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _490 = (d.z > 0.0) ? 4 : 5;\n        }\n        _477 = _490;\n    }\n    return _477;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _416 = dot(d, right);\n    float _420 = dot(d, up);\n    float _431;\n    if (((_416 * _416) + (_420 * _420)) > 1.0000000133514319600180897396058e-10)\n    {\n        _431 = atan(_420, _416) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _431 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_431 - floor(_431)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _708 = fa_light_base(param);\n    bool _712 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _708;\n    vec4 _716 = fa_light_texel(param_1);\n    int param_2 = _708 + 1;\n    vec4 _721 = fa_light_texel(param_2);\n    float _724 = _721.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _736 = _712 && (_724 > 2.5);\n    fa_light_is_area = _736;\n    bool _738 = _724 < 0.5;\n    vec3 l;\n    if (_738)\n    {\n        l = normalize(_716.xyz);\n        if (_712)\n        {\n            int param_3 = _708 + 6;\n            vec4 _752 = fa_light_texel(param_3);\n            if (_752.z > 0.5)\n            {\n                int param_4 = _708 + 4;\n                vec4 _762 = fa_light_texel(param_4);\n                int param_5 = _708 + 5;\n                vec4 _767 = fa_light_texel(param_5);\n                vec2 param_6 = _752.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _762.xyz) * _762.w, (-dot(world_pos, _767.xyz)) * _767.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _797 = _716.xyz;\n        vec3 _799 = _797 - world_pos;\n        vec3 to_light = _799;\n        float _802 = length(_799);\n        float reach = _802;\n        bool front = true;\n        if (_736)\n        {\n            int param_8 = _708 + 7;\n            reach = max(_802 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _708 + 4;\n            vec4 _826 = fa_light_texel(param_9);\n            int param_10 = _708 + 5;\n            vec4 _831 = fa_light_texel(param_10);\n            int param_11 = _708 + 6;\n            vec4 _836 = fa_light_texel(param_11);\n            float _837 = _836.w;\n            int param_12 = _708 + 2;\n            vec3 _844 = normalize(fa_light_texel(param_12).xyz);\n            bool _846 = _837 > 1.5;\n            bool _854;\n            if (!_846)\n            {\n                _854 = dot(_844, to_light) < 0.0;\n            }\n            else\n            {\n                _854 = _846;\n            }\n            front = _854;\n            vec3 r = vec3(0.0);\n            vec3 _863 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _867 = dot(n, n) > 0.5;\n            bool _875;\n            if (_867)\n            {\n                _875 = dot(_863, _863) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _875 = _867;\n            }\n            if (_875)\n            {\n                r = reflect(-normalize(_863), normalize(n));\n            }\n            vec3 param_13 = _797;\n            vec3 param_14 = _844;\n            vec3 param_15 = _826.xyz;\n            vec3 param_16 = _831.xyz;\n            float param_17 = _826.w;\n            float param_18 = _831.w;\n            float param_19 = _837;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _911 = length(to_light);\n        dist = _911;\n        l = to_light / vec3(max(_911, 9.9999997473787516355514526367188e-05));\n        float _925 = reach / max(_716.w, 0.001000000047497451305389404296875);\n        float _931 = clamp(1.0 - (_925 * _925), 0.0, 1.0);\n        float _933;\n        if (front)\n        {\n            _933 = _931 * _931;\n        }\n        else\n        {\n            _933 = 0.0;\n        }\n        atten = _933;\n        bool _944 = _724 < 2.5;\n        if ((_724 > 1.5) && _944)\n        {\n            int param_22 = _708 + 2;\n            vec4 _952 = fa_light_texel(param_22);\n            float _962 = _952.w;\n            int param_23 = _708 + 3;\n            vec4 _967 = fa_light_texel(param_23);\n            float _968 = _967.x;\n            float cos_inner = _968;\n            if (_968 > 1.5)\n            {\n                cos_inner = mix(_962, 1.0, 0.25);\n            }\n            atten *= smoothstep(_962, cos_inner, dot(-l, normalize(_952.xyz)));\n        }\n        if (_712 && (_724 < 1.5))\n        {\n            int param_24 = _708 + 6;\n            vec4 _992 = fa_light_texel(param_24);\n            if (_992.z > 0.5)\n            {\n                vec3 _1000 = -to_light;\n                int param_25 = _708 + 4;\n                int param_26 = _708 + 5;\n                vec3 _1014 = fa_light_texel(param_25).xyz;\n                vec3 _1018 = fa_light_texel(param_26).xyz;\n                vec3 _1027 = vec3(dot(_1000, _1014), dot(_1000, _1018), dot(_1000, cross(_1014, _1018)));\n                vec3 param_27 = _1027;\n                int _1031 = fa_cube_face(param_27);\n                int param_28 = _1031;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1058 = vec2(dot(_1027, cross(param_29, param_30)), dot(_1027, param_30)) / vec2(max(dot(_1027, param_29), 9.9999997473787516355514526367188e-05));\n                int _1062 = _1031 / 3;\n                vec2 param_31 = _992.xy + (vec2(float(_1031 - (_1062 * 3)), float(_1062)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1058.x), 0.5 - (0.5 * _1058.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _708 + 7;\n            vec4 _1092 = fa_light_texel(param_33);\n            if (_1092.z > 0.5)\n            {\n                int param_34 = _708 + 2;\n                int param_35 = _708 + 4;\n                int param_36 = _708 + 5;\n                vec2 param_37 = _1092.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_712 && _944)\n            {\n                int param_42 = _708 + 6;\n                vec4 _1139 = fa_light_texel(param_42);\n                int param_43 = _708 + 7;\n                vec4 _1144 = fa_light_texel(param_43);\n                bool _1147 = _1139.z > 0.5;\n                bool _1154;\n                if (!_1147)\n                {\n                    _1154 = _1144.z > 0.5;\n                }\n                else\n                {\n                    _1154 = _1147;\n                }\n                if (_1154)\n                {\n                    int param_44 = _708 + 2;\n                    vec4 _1161 = fa_light_texel(param_44);\n                    vec3 _1165 = normalize(_1161.xyz);\n                    int param_45 = _708 + 4;\n                    vec4 _1170 = fa_light_texel(param_45);\n                    int param_46 = _708 + 5;\n                    vec4 _1175 = fa_light_texel(param_46);\n                    if (_1147)\n                    {\n                        vec3 _1183 = -to_light;\n                        float _1190 = _1161.w;\n                        float _1206 = 0.5 / max(dot(_1183, _1165) * (sqrt(max(1.0 - (_1190 * _1190), 0.0)) / max(_1190, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1139.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1183, _1170.xyz) * _1206), 0.5 - (dot(_1183, _1175.xyz) * _1206));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1144.z > 0.5)\n                    {\n                        vec2 param_49 = _1144.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1165;\n                        vec3 param_52 = _1170.xyz;\n                        vec3 param_53 = _1175.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _4141 = _721.xyz * atten;\n    if (_712)\n    {\n        _4141 *= fa_light_tint;\n    }\n    int _1274;\n    if (_738)\n    {\n        _1274 = 0;\n    }\n    else\n    {\n        _1274 = ((_724 > 1.5) && (_724 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4141, atten, 1.0, dist, _1274);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2011;\n    if (i == 0)\n    {\n        _2011 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2027;\n        if (i == 1)\n        {\n            _2027 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2035;\n            if (i == 2)\n            {\n                _2035 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2035 = fa_shadows[24].w;\n            }\n            _2027 = _2035;\n        }\n        _2011 = _2027;\n    }\n    return _2011;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2068 = fa_shadow_depth(param, param_1);\n    float _2072;\n    if (conv.x < 0.5)\n    {\n        _2072 = _2068;\n    }\n    else\n    {\n        _2072 = (conv.y * conv.z) / (conv.z - (_2068 * (conv.z - conv.y)));\n    }\n    return _2072;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1999 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1999), sin(_1999)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2118 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2127;\n        if (k < 0.0)\n        {\n            _2127 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2127 = k;\n        }\n        float _2147 = clamp((_2127 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2118;\n            vec2 _2166 = fa_shadow_vogel(param_3, param_4, param_5) * _2147;\n            vec2 param_6 = uv + (_2166 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2178 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2178 < (zr - (length(_2166) * plane)))\n            {\n                sum += _2178;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2204 = sum / cnt;\n        float _2214;\n        if (k < 0.0)\n        {\n            _2214 = (-k) / max(_2204, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2214 = k;\n        }\n        radius = clamp(((max(zr - _2204, 0.0) * unit) * _2214) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2236 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2236; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2236;\n        float param_11 = _2118;\n        vec2 _2255 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2255 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2255) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2236);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2297 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2302 = clamp(dot(n, l), 0.0, 1.0);\n    float _2308 = sqrt(1.0 - (_2302 * _2302));\n    float _2315 = min(_2308 / max(_2302, 0.20000000298023223876953125), 4.0);\n    float _2320;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2320 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2320 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2345 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2320 * _2308)), 1.0);\n    float _2352 = _2345.x;\n    bool _2355 = _2352 < fa_shadows[ci * 1 + 16].x;\n    bool _2364;\n    if (!_2355)\n    {\n        _2364 = _2352 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2364 = _2355;\n    }\n    bool _2373;\n    if (!_2364)\n    {\n        _2373 = _2345.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2373 = _2364;\n    }\n    bool _2382;\n    if (!_2373)\n    {\n        _2382 = _2345.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2382 = _2373;\n    }\n    bool _2389;\n    if (!_2382)\n    {\n        _2389 = _2345.z > 1.0;\n    }\n    else\n    {\n        _2389 = _2382;\n    }\n    if (_2389)\n    {\n        return -1.0;\n    }\n    float _2397;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2397 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2397 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2345.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2345.z - ((_2397 * (1.0 + (0.5 * _2315))) / _2297);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2297;\n    float param_5 = _2297 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2315, 3.0)) * 0.5) / _2297;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2785 = int(fa_shadows[25].x + 0.5);\n    if (_2785 < 1)\n    {\n        return 1.0;\n    }\n    float _2800 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2785 - 1;\n    if (_2800 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2812 = _2785 > 1;\n    bool _2819;\n    if (_2812)\n    {\n        _2819 = _2800 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2819 = _2812;\n    }\n    if (_2819)\n    {\n        ci = 1;\n    }\n    bool _2823 = _2785 > 2;\n    bool _2830;\n    if (_2823)\n    {\n        _2830 = _2800 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2830 = _2823;\n    }\n    if (_2830)\n    {\n        ci = 2;\n    }\n    bool _2834 = _2785 > 3;\n    bool _2841;\n    if (_2834)\n    {\n        _2841 = _2800 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2841 = _2834;\n    }\n    if (_2841)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2785)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2867 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2867;\n        if (_2867 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2892;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2892 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2892 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2911 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2892, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2922 = clamp((_2800 - (fa_shadow_split_at(param_7) - _2911)) / _2911, 0.0, 1.0);\n        if (_2922 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2785)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2943 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2943;\n                if (_2943 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2922);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _2455 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2462;\n    if (!_2455)\n    {\n        _2462 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2462 = _2455;\n    }\n    if (_2462)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2475 = fa_light_texel(param);\n    float _2476 = _2475.x;\n    if (_2476 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2485 = int(_2476 + 0.5);\n    int param_1 = _2485;\n    vec4 _2489 = fa_light_texel(param_1);\n    int param_2 = _2485 + 1;\n    vec4 _2494 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2497 = _2489.y;\n    if (_2497 > 0.0)\n    {\n        float _2514 = 1.0 - smoothstep(0.75 * _2497, _2497, length(world - fa_shadows[27].xyz));\n        fade = _2514;\n        if (_2514 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2489.x > 1.5)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        vec3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2543 = (_2485 + 2) + (face * 6);\n    int param_6 = _2543;\n    int param_7 = _2543 + 1;\n    int param_8 = _2543 + 3;\n    vec4 _2557 = fa_light_texel(param_8);\n    int param_9 = _2543 + 4;\n    vec4 _2562 = fa_light_texel(param_9);\n    int param_10 = _2543 + 5;\n    vec4 _2567 = fa_light_texel(param_10);\n    float _2579 = _2567.x * max(dot(_2557, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2584 = clamp(dot(n, l), 0.0, 1.0);\n    float _2607 = clamp(dot(n, _2557.xyz), -1.0, 1.0);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2631 = min(sqrt(1.0 - (_2607 * _2607)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2557, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2634 = _2494.y;\n    float _2636;\n    if (_2634 > 0.0)\n    {\n        _2636 = _2634;\n    }\n    else\n    {\n        _2636 = 1.5 * _2579;\n    }\n    vec4 _2656 = vec4(world + (n * (_2636 * sqrt(1.0 - (_2584 * _2584)))), 1.0);\n    float _2660 = dot(_2557, _2656);\n    float _2663 = _2567.y;\n    if (_2660 < _2663)\n    {\n        return 1.0;\n    }\n    vec2 _2678 = vec2(dot(fa_light_texel(param_6), _2656), dot(fa_light_texel(param_7), _2656)) / vec2(_2660);\n    float _2680 = _2678.x;\n    bool _2683 = _2680 < _2562.x;\n    bool _2692;\n    if (!_2683)\n    {\n        _2692 = _2680 > _2562.z;\n    }\n    else\n    {\n        _2692 = _2683;\n    }\n    bool _2701;\n    if (!_2692)\n    {\n        _2701 = _2678.y < _2562.y;\n    }\n    else\n    {\n        _2701 = _2692;\n    }\n    bool _2710;\n    if (!_2701)\n    {\n        _2710 = _2678.y > _2562.w;\n    }\n    else\n    {\n        _2710 = _2701;\n    }\n    if (_2710)\n    {\n        return 1.0;\n    }\n    float _2716 = _2494.x;\n    float _2718;\n    if (_2716 > 0.0)\n    {\n        _2718 = _2716;\n    }\n    else\n    {\n        _2718 = 1.5 * _2579;\n    }\n    vec2 param_13 = _2678;\n    vec4 param_14 = _2562;\n    float param_15 = _2660 - (_2718 * (1.0 + (0.5 * _2631)));\n    float param_16 = _2579;\n    float param_17 = 1.0;\n    float param_18 = _2567.z * 0.25;\n    float param_19 = (_2579 * min(_2631, 3.0)) * 0.5;\n    vec3 param_20 = vec3(1.0, _2663, _2567.z);\n    int param_21 = int(_2489.z + 0.5);\n    float param_22 = _2489.w;\n    return mix(1.0, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3110 = fa_lm.z > 0.5;\n    bool _3116;\n    if (_3110)\n    {\n        int param = li;\n        _3116 = fa_light_baked(param);\n    }\n    else\n    {\n        _3116 = _3110;\n    }\n    if (_3116)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3140 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _4167 = _3140.color;\n    float _4169 = _3140.shadow;\n    if ((_3140.type == 0) && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3140.direction;\n        float _3154 = fa_shadow_factor(param_5, param_6);\n        _4169 = _3154;\n        _4167 *= _3154;\n    }\n    else\n    {\n        bool _3165 = _3140.type != 0;\n        bool _3171;\n        if (_3165)\n        {\n            _3171 = _3140.attenuation > 0.0;\n        }\n        else\n        {\n            _3171 = _3165;\n        }\n        if (_3171)\n        {\n            int param_7 = li;\n            vec3 param_8 = world_pos;\n            vec3 param_9 = gn;\n            vec3 param_10 = _3140.direction;\n            float _3183 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _4169 = _3183;\n            _4167 *= _3183;\n        }\n    }\n    return LightSample(_3140.direction, _4167, _3140.attenuation, _4169, _3140._distance, _3140.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _3203;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _3203 = 1.0;\n    }\n    else\n    {\n        _3203 = fa_material[0].x;\n    }\n    return (s.albedo * l.color) * _3203;\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2967 = int(fa_shadows[25].x + 0.5);\n    float _2977 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2982 = _2967 > 0;\n    bool _2991;\n    if (_2982)\n    {\n        int param = _2967 - 1;\n        _2991 = _2977 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2991 = _2982;\n    }\n    if (_2991)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2997 = _2967 > 1;\n        bool _3004;\n        if (_2997)\n        {\n            _3004 = _2977 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3004 = _2997;\n        }\n        if (_3004)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3010 = _2967 > 2;\n        bool _3017;\n        if (_3010)\n        {\n            _3017 = _2977 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3017 = _3010;\n        }\n        if (_3017)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3023 = _2967 > 3;\n        bool _3030;\n        if (_3023)\n        {\n            _3030 = _2977 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3030 = _3023;\n        }\n        if (_3030)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4008 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4008 = -_4008;\n    }\n    vec3 _3592 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4008, fa_world_tangent, fa_uv, fa_vertex_color, _3592, gl_FrontFacing);\n    Surface _3600 = fa_standard_surface(param_1);\n    vec3 _4039 = _3600.albedo;\n    float _4040 = _3600.alpha;\n    vec3 _4041 = _3600.normal;\n    float _4042 = _3600.metallic;\n    float _4043 = _3600.roughness;\n    float _4044 = _3600.occlusion;\n    vec3 _4045 = _3600.emission;\n    float _4046 = _3600.clearcoat;\n    float _4047 = _3600.clearcoat_roughness;\n    vec3 _4048 = _3600.sheen_color;\n    float _4049 = _3600.sheen_roughness;\n    float _4050 = _3600.anisotropy;\n    float _4051 = _3600.anisotropy_rotation;\n    float _4052 = _3600.specular;\n    float _4053 = _3600.ior;\n    vec3 _4054 = _3600.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4008, fa_world_tangent, fa_uv, fa_vertex_color, _3592, gl_FrontFacing);\n    Surface param_3 = _3600;\n    surface(param_2, param_3);\n    _4039 = param_3.albedo;\n    _4040 = param_3.alpha;\n    _4041 = param_3.normal;\n    _4042 = param_3.metallic;\n    _4043 = param_3.roughness;\n    _4044 = param_3.occlusion;\n    _4045 = param_3.emission;\n    _4046 = param_3.clearcoat;\n    _4047 = param_3.clearcoat_roughness;\n    _4048 = param_3.sheen_color;\n    _4049 = param_3.sheen_roughness;\n    _4050 = param_3.anisotropy;\n    _4051 = param_3.anisotropy_rotation;\n    _4052 = param_3.specular;\n    _4053 = param_3.ior;\n    _4054 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4008;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4039 = param_6;\n    _4041 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4039;\n    }\n    else\n    {\n        vec3 _3638 = _4041;\n        vec3 _3639 = normalize(_3638);\n        _4041 = _3639;\n        vec3 param_8 = _3639;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _4039) * _4044;\n        int _3658 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3658; ln++)\n        {\n            int param_9 = ln;\n            int _3671 = fa_cl_light(param_9);\n            bool _3674 = fa_lm.z > 0.5;\n            bool _3680;\n            if (_3674)\n            {\n                int param_10 = _3671;\n                _3680 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _3680 = _3674;\n            }\n            if (_3680)\n            {\n                continue;\n            }\n            int param_11 = _3671;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _4008;\n            LightSample _3692 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _4008, fa_world_tangent, fa_uv, fa_vertex_color, _3592, gl_FrontFacing);\n            Surface param_15 = Surface(_4039, _4040, _4041, _4042, _4043, _4044, _4045, _4046, _4047, _4048, _4049, _4050, _4051, _4052, _4053, _4054);\n            LightSample param_16 = _3692;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _3707 = result;\n    vec3 _3708 = _3707 + _4045;\n    result = _3708;\n    vec3 param_17 = _3708;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _3717 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3724;\n    if (!_3717)\n    {\n        _3724 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3724 = _3717;\n    }\n    if (_3724)\n    {\n        vec3 _3733 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3739 = dot(_3733, fa_mesh_fs_params[9].xyz);\n        bool _3743 = fa_mesh_fs_params[9].w > 0.5;\n        float _3744;\n        if (_3743)\n        {\n            _3744 = _3739;\n        }\n        else\n        {\n            _3744 = length(_3733);\n        }\n        float _3756 = _3744 - fa_mesh_fs_params[8].x;\n        if (_3756 > 0.0)\n        {\n            float _3765 = fa_mesh_fs_params[7].w * _3756;\n            float tau = _3765 * _3765;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3781;\n                if (_3743)\n                {\n                    _3781 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3739);\n                }\n                else\n                {\n                    _3781 = fa_mesh_fs_params[0].y;\n                }\n                float _3802 = mix(_3781, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3744, 0.0, 1.0));\n                float _3806 = fa_world_pos.y - _3802;\n                float _3811 = _3802 - fa_mesh_fs_params[8].z;\n                float _3816 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3819 = _3811 <= 0.0;\n                bool _3820 = !_3819;\n                bool _3826;\n                if (_3820)\n                {\n                    _3826 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3826 = _3819;\n                }\n                float _3827;\n                if (_3826)\n                {\n                    _3827 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3827 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3811, 80.0));\n                }\n                bool _3854;\n                if (_3820)\n                {\n                    _3854 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3854 = _3819;\n                }\n                float _3855;\n                if (_3854)\n                {\n                    _3855 = fa_mesh_fs_params[8].y * _3811;\n                }\n                else\n                {\n                    _3855 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3811, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3880 = _3816 <= 0.0;\n                bool _3887;\n                if (!_3880)\n                {\n                    _3887 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3887 = _3880;\n                }\n                float _3888;\n                if (_3887)\n                {\n                    _3888 = fa_mesh_fs_params[8].y * _3816;\n                }\n                else\n                {\n                    _3888 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3816, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3915;\n                if (abs(_3806) < 0.001000000047497451305389404296875)\n                {\n                    _3915 = _3827;\n                }\n                else\n                {\n                    _3915 = (_3888 - _3855) / _3806;\n                }\n                tau += (_3756 * max(_3915, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4040);\n}\n\n",
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
            "inst_name": "_2021",
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
            "inst_name": "_3209",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _302 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _788 = base_t;\n    _788.x = _225.x;\n    _788.y = _225.y;\n    _788.z = _225.z;\n    base_t = _788;\n    vec4 _241 = (_788 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _751 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _796 = _279;\n        _796.x = _284.x;\n        _796.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _796;\n        _751 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _799 = mrt;\n    _799.x = _313.x;\n    _799.y = _313.y;\n    _799.z = _313.z;\n    mrt = _799;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _756 = fa_mesh_fs_params[20].x;\n    float _757 = fa_mesh_fs_params[20].y;\n    float _760 = fa_mesh_fs_params[20].z;\n    float _759 = fa_mesh_fs_params[21].w;\n    float _762 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _756 *= _355.y;\n            _757 *= _355.z;\n            _759 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _760 *= mrt.x;\n            _762 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _751, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _756, _757, fa_mesh_fs_params[21].xyz, _759, _760, fa_mesh_fs_params[20].w, _762, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _662 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _662 = -_662;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _662, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _662, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _423 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_423, 1.0);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _788 = base_t;\n    _788.x = _225.x;\n    _788.y = _225.y;\n    _788.z = _225.z;\n    base_t = _788;\n    vec4 _241 = (_788 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _751 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _796 = _279;\n        _796.x = _284.x;\n        _796.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _796;\n        _751 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _799 = mrt;\n    _799.x = _313.x;\n    _799.y = _313.y;\n    _799.z = _313.z;\n    mrt = _799;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _756 = fa_mesh_fs_params[20].x;\n    float _757 = fa_mesh_fs_params[20].y;\n    float _760 = fa_mesh_fs_params[20].z;\n    float _759 = fa_mesh_fs_params[21].w;\n    float _762 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _756 *= _355.y;\n            _757 *= _355.z;\n            _759 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _760 *= mrt.x;\n            _762 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _751, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _756, _757, fa_mesh_fs_params[21].xyz, _759, _760, fa_mesh_fs_params[20].w, _762, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _662 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _662 = -_662;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _662, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _662, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
