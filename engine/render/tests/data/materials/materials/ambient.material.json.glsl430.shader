{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "fc5698cd941e0af057040ef4c307a7106b1e2971cc74f7501935817daedb7ce8",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1298 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1305;\n    if (!_1298)\n    {\n        _1305 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1305 = _1298;\n    }\n    bool _1313;\n    if (!_1305)\n    {\n        _1313 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1313 = _1305;\n    }\n    bool _1320;\n    if (!_1313)\n    {\n        _1320 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1320 = _1313;\n    }\n    bool _1327;\n    if (!_1320)\n    {\n        _1327 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1327 = _1320;\n    }\n    if (_1327)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1337 = vec4(world_pos, 1.0);\n    float _1343 = dot(fa_mesh_fs_params[16], _1337);\n    if (!(_1343 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1365 = vec2(dot(fa_mesh_fs_params[14], _1337), dot(fa_mesh_fs_params[15], _1337)) / vec2(_1343);\n    int _1369 = int(fa_mesh_fs_params[18].x);\n    int _1373 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1373) + clamp(int(floor(((_1365.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1373 - 1)) * _1369)) + clamp(int(floor(((_1365.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1369 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1449 = fa_cluster_texel(param);\n    return ivec2(int(_1449.x), int(_1449.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3089 = fa_cluster_lookup(param);\n    fa_cl_slot = _3089.x;\n    fa_cl_local = _3089.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3243 = fa_linear_to_srgb(param);\n        c = _3243;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3251 = fa_srgb_to_linear(param_1);\n            c = _3251;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _252;\n    if (i.front_facing)\n    {\n        _252 = i.world_normal;\n    }\n    else\n    {\n        _252 = -i.world_normal;\n    }\n    vec3 _276 = normalize(i.world_tangent.xyz - (_252 * dot(_252, i.world_tangent.xyz)));\n    vec3 _304 = normalize(((_276 * m.x) + ((cross(_252, _276) * i.world_tangent.w) * m.y)) + (_252 * m.z));\n    vec3 _307;\n    if (i.front_facing)\n    {\n        _307 = _304;\n    }\n    else\n    {\n        _307 = -_304;\n    }\n    return _307;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3282 = fa_tex_fix(param_2, param_3);\n    vec4 _4332 = base_t;\n    _4332.x = _3282.x;\n    _4332.y = _3282.y;\n    _4332.z = _3282.z;\n    base_t = _4332;\n    vec4 _3296 = (_4332 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4197 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3328 = fa_tex_fix(param_6, param_7);\n        vec3 _3331 = (_3328 * 2.0) - vec3(1.0);\n        vec2 _3336 = _3331.xy * fa_mesh_fs_params[6].x;\n        vec3 _4340 = _3331;\n        _4340.x = _3336.x;\n        _4340.y = _3336.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4340;\n        _4197 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3364 = fa_tex_fix(param_12, param_13);\n    vec4 _4343 = mrt;\n    _4343.x = _3364.x;\n    _4343.y = _3364.y;\n    _4343.z = _3364.z;\n    mrt = _4343;\n    vec4 _3392 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3392.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3403 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3433 = fa_tex_fix(param_20, param_21);\n    float _4202 = fa_mesh_fs_params[20].x;\n    float _4203 = fa_mesh_fs_params[20].y;\n    float _4206 = fa_mesh_fs_params[20].z;\n    float _4205 = fa_mesh_fs_params[21].w;\n    float _4208 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4202 *= _3403.y;\n            _4203 *= _3403.z;\n            _4205 *= _3392.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4206 *= mrt.x;\n            _4208 *= mrt.w;\n        }\n    }\n    return Surface(_3296.xyz, _3296.w, _4197, clamp(fa_mesh_fs_params[5].x * _3364.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3364.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3403.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3433), _4202, _4203, fa_mesh_fs_params[21].xyz, _4205, _4206, fa_mesh_fs_params[20].w, _4208, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1529 = rect.zw - rect.xy;\n    vec2 _1533 = _1529 * atlas;\n    vec2 _1537 = ddx * _1533;\n    vec2 _1541 = ddy * _1533;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1529), clamp(0.5 * log2(max(max(dot(_1537, _1537), dot(_1541, _1541)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1574 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1581;\n    if (!_1574)\n    {\n        _1581 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1581 = _1574;\n    }\n    if (_1581)\n    {\n        return;\n    }\n    vec3 _1587 = dFdx(world_pos);\n    vec3 _1590 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1594 = fa_cluster_texel(param);\n    int _1598 = int(_1594.w);\n    if (_1598 < 1)\n    {\n        return;\n    }\n    int _1608 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1608;\n    vec4 _1612 = fa_light_texel(param_1);\n    vec2 _1615 = _1612.yz;\n    int _1619 = int(_1612.w);\n    int param_2 = _1608 + 1;\n    vec4 _1624 = fa_light_texel(param_2);\n    float _1625 = _1624.x;\n    int _1631 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1635 = int(_1594.z);\n    vec3 _1900;\n    for (int k = 0; k < _1598; k++)\n    {\n        int _1648 = _1635 + k;\n        int param_3 = _1619 + (_1648 >> 2);\n        int _1665 = (_1608 + 2) + (int(fa_light_texel(param_3)[_1648 & 3]) * 7);\n        int param_4 = _1665 + 6;\n        vec4 _1670 = fa_light_texel(param_4);\n        if (((int(_1670.w + 0.5) >> _1631) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1665;\n        vec4 _1685 = fa_light_texel(param_5);\n        int param_6 = _1665 + 1;\n        vec4 _1690 = fa_light_texel(param_6);\n        int param_7 = _1665 + 2;\n        vec4 _1695 = fa_light_texel(param_7);\n        vec3 _1698 = _1685.xyz;\n        float _1703 = dot(_1698, world_pos) + _1685.w;\n        vec3 _1705 = _1690.xyz;\n        float _1710 = dot(_1705, world_pos) + _1690.w;\n        vec3 _1712 = _1695.xyz;\n        float _1717 = dot(_1712, world_pos) + _1695.w;\n        bool _1722 = abs(_1703) > 0.5;\n        bool _1730;\n        if (!_1722)\n        {\n            _1730 = abs(_1710) > 0.5;\n        }\n        else\n        {\n            _1730 = _1722;\n        }\n        bool _1738;\n        if (!_1730)\n        {\n            _1738 = abs(_1717) > 0.5;\n        }\n        else\n        {\n            _1738 = _1730;\n        }\n        if (_1738)\n        {\n            continue;\n        }\n        float _1753 = clamp(dot(geo_normal, normalize(_1712)) * _1670.z, 0.0, 1.0);\n        if (_1753 <= 0.0)\n        {\n            continue;\n        }\n        float _1773 = (clamp((0.5 - abs(_1717)) * 10.0, 0.0, 1.0) * _1753) * _1670.x;\n        vec2 _1781 = vec2(_1703 + 0.5, 0.5 - _1710);\n        vec2 _1791 = vec2(dot(_1698, _1587), dot(_1705, _1587));\n        vec2 _1801 = vec2(dot(_1698, _1590), dot(_1705, _1590));\n        int param_8 = _1665 + 5;\n        vec4 _1806 = fa_light_texel(param_8);\n        int param_9 = _1665 + 3;\n        vec4 _1811 = fa_light_texel(param_9);\n        int param_10 = _1665 + 4;\n        vec4 _1816 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1806.xyz;\n        bool _1826 = _1811.z > _1811.x;\n        if (_1826)\n        {\n            vec4 param_11 = _1811;\n            vec2 param_12 = _1781;\n            vec2 param_13 = _1615;\n            vec2 param_14 = _1791;\n            vec2 param_15 = _1801;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1625 > 0.5) && (_1625 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1852 = fa_dc_to_linear(param_16);\n                vec4 _4277 = tx;\n                _4277.x = _1852.x;\n                _4277.y = _1852.y;\n                _4277.z = _1852.z;\n                tx = _4277;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1773 * tex_a) * _1806.w, 0.0, 1.0)));\n        if (_1816.z > _1816.x)\n        {\n            vec4 param_17 = _1816;\n            vec2 param_18 = _1781;\n            vec2 param_19 = _1615;\n            vec2 param_20 = _1791;\n            vec2 param_21 = _1801;\n            vec4 _1896 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1625 > 1.5)\n            {\n                vec3 param_22 = _1896.xyz;\n                vec3 _1906 = fa_dc_to_srgb(param_22);\n                _1900 = _1906;\n            }\n            else\n            {\n                _1900 = _1896.xyz;\n            }\n            vec3 _1915 = (_1900 * 2.0) - vec3(1.0);\n            vec2 _1920 = _1915.xy * _1670.y;\n            vec3 _1942 = (normalize(_1698) * _1920.x) + (normalize(_1705) * _1920.y);\n            vec3 _1945 = normalize(normal);\n            normal = normalize(mix(_1945, normalize((_1945 * max(_1915.z, 0.0500000007450580596923828125)) + (_1942 - (_1945 * dot(_1945, _1942)))), vec3(clamp(_1773 * (_1826 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _548 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _561 = (c - (ru * hx)) - p;\n        vec3 _567 = ru * (2.0 * hx);\n        float _573 = max(dot(_567, _567), 9.9999999392252902907785028219223e-09);\n        float _577 = dot(_561, _567);\n        float t = clamp((-_577) / _573, 0.0, 1.0);\n        if (_548)\n        {\n            float _592 = dot(r, _567);\n            float _598 = _573 - (_592 * _592);\n            if (abs(_598) > (9.9999997473787516355514526367188e-06 * _573))\n            {\n                t = clamp(((dot(r, _561) * _592) - _577) / _598, 0.0, 1.0);\n            }\n        }\n        return (p + _561) + (_567 * t);\n    }\n    vec3 q = p;\n    float _630 = dot(r, axis);\n    bool _638;\n    if (_548)\n    {\n        _638 = abs(_630) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _638 = _548;\n    }\n    if (_638)\n    {\n        float _648 = dot(c - p, axis) / _630;\n        if (_648 > 0.0)\n        {\n            q = p + (r * _648);\n        }\n    }\n    vec3 _661 = q - c;\n    vec2 xy = vec2(dot(_661, ru), dot(_661, uu));\n    if (shape > 0.5)\n    {\n        float _676 = length(xy);\n        if (_676 > hx)\n        {\n            xy *= (hx / _676);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _469 = abs(d);\n    float _471 = _469.x;\n    float _473 = _469.y;\n    bool _474 = _471 >= _473;\n    bool _482;\n    if (_474)\n    {\n        _482 = _471 >= _469.z;\n    }\n    else\n    {\n        _482 = _474;\n    }\n    int _483;\n    if (_482)\n    {\n        _483 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _496;\n        if (_473 >= _469.z)\n        {\n            _496 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _496 = (d.z > 0.0) ? 4 : 5;\n        }\n        _483 = _496;\n    }\n    return _483;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _422 = dot(d, right);\n    float _426 = dot(d, up);\n    float _437;\n    if (((_422 * _422) + (_426 * _426)) > 1.0000000133514319600180897396058e-10)\n    {\n        _437 = atan(_426, _422) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _437 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_437 - floor(_437)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _714 = fa_light_base(param);\n    bool _718 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _714;\n    vec4 _722 = fa_light_texel(param_1);\n    int param_2 = _714 + 1;\n    vec4 _727 = fa_light_texel(param_2);\n    float _730 = _727.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _742 = _718 && (_730 > 2.5);\n    fa_light_is_area = _742;\n    bool _744 = _730 < 0.5;\n    vec3 l;\n    if (_744)\n    {\n        l = normalize(_722.xyz);\n        if (_718)\n        {\n            int param_3 = _714 + 6;\n            vec4 _758 = fa_light_texel(param_3);\n            if (_758.z > 0.5)\n            {\n                int param_4 = _714 + 4;\n                vec4 _768 = fa_light_texel(param_4);\n                int param_5 = _714 + 5;\n                vec4 _773 = fa_light_texel(param_5);\n                vec2 param_6 = _758.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _768.xyz) * _768.w, (-dot(world_pos, _773.xyz)) * _773.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _803 = _722.xyz;\n        vec3 _805 = _803 - world_pos;\n        vec3 to_light = _805;\n        float _808 = length(_805);\n        float reach = _808;\n        bool front = true;\n        if (_742)\n        {\n            int param_8 = _714 + 7;\n            reach = max(_808 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _714 + 4;\n            vec4 _832 = fa_light_texel(param_9);\n            int param_10 = _714 + 5;\n            vec4 _837 = fa_light_texel(param_10);\n            int param_11 = _714 + 6;\n            vec4 _842 = fa_light_texel(param_11);\n            float _843 = _842.w;\n            int param_12 = _714 + 2;\n            vec3 _850 = normalize(fa_light_texel(param_12).xyz);\n            bool _852 = _843 > 1.5;\n            bool _860;\n            if (!_852)\n            {\n                _860 = dot(_850, to_light) < 0.0;\n            }\n            else\n            {\n                _860 = _852;\n            }\n            front = _860;\n            vec3 r = vec3(0.0);\n            vec3 _869 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _873 = dot(n, n) > 0.5;\n            bool _881;\n            if (_873)\n            {\n                _881 = dot(_869, _869) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _881 = _873;\n            }\n            if (_881)\n            {\n                r = reflect(-normalize(_869), normalize(n));\n            }\n            vec3 param_13 = _803;\n            vec3 param_14 = _850;\n            vec3 param_15 = _832.xyz;\n            vec3 param_16 = _837.xyz;\n            float param_17 = _832.w;\n            float param_18 = _837.w;\n            float param_19 = _843;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _917 = length(to_light);\n        dist = _917;\n        l = to_light / vec3(max(_917, 9.9999997473787516355514526367188e-05));\n        float _931 = reach / max(_722.w, 0.001000000047497451305389404296875);\n        float _937 = clamp(1.0 - (_931 * _931), 0.0, 1.0);\n        float _939;\n        if (front)\n        {\n            _939 = _937 * _937;\n        }\n        else\n        {\n            _939 = 0.0;\n        }\n        atten = _939;\n        bool _950 = _730 < 2.5;\n        if ((_730 > 1.5) && _950)\n        {\n            int param_22 = _714 + 2;\n            vec4 _958 = fa_light_texel(param_22);\n            float _968 = _958.w;\n            int param_23 = _714 + 3;\n            vec4 _973 = fa_light_texel(param_23);\n            float _974 = _973.x;\n            float cos_inner = _974;\n            if (_974 > 1.5)\n            {\n                cos_inner = mix(_968, 1.0, 0.25);\n            }\n            atten *= smoothstep(_968, cos_inner, dot(-l, normalize(_958.xyz)));\n        }\n        if (_718 && (_730 < 1.5))\n        {\n            int param_24 = _714 + 6;\n            vec4 _998 = fa_light_texel(param_24);\n            if (_998.z > 0.5)\n            {\n                vec3 _1006 = -to_light;\n                int param_25 = _714 + 4;\n                int param_26 = _714 + 5;\n                vec3 _1020 = fa_light_texel(param_25).xyz;\n                vec3 _1024 = fa_light_texel(param_26).xyz;\n                vec3 _1033 = vec3(dot(_1006, _1020), dot(_1006, _1024), dot(_1006, cross(_1020, _1024)));\n                vec3 param_27 = _1033;\n                int _1037 = fa_cube_face(param_27);\n                int param_28 = _1037;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1064 = vec2(dot(_1033, cross(param_29, param_30)), dot(_1033, param_30)) / vec2(max(dot(_1033, param_29), 9.9999997473787516355514526367188e-05));\n                int _1068 = _1037 / 3;\n                vec2 param_31 = _998.xy + (vec2(float(_1037 - (_1068 * 3)), float(_1068)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1064.x), 0.5 - (0.5 * _1064.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _714 + 7;\n            vec4 _1098 = fa_light_texel(param_33);\n            if (_1098.z > 0.5)\n            {\n                int param_34 = _714 + 2;\n                int param_35 = _714 + 4;\n                int param_36 = _714 + 5;\n                vec2 param_37 = _1098.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_718 && _950)\n            {\n                int param_42 = _714 + 6;\n                vec4 _1145 = fa_light_texel(param_42);\n                int param_43 = _714 + 7;\n                vec4 _1150 = fa_light_texel(param_43);\n                bool _1153 = _1145.z > 0.5;\n                bool _1160;\n                if (!_1153)\n                {\n                    _1160 = _1150.z > 0.5;\n                }\n                else\n                {\n                    _1160 = _1153;\n                }\n                if (_1160)\n                {\n                    int param_44 = _714 + 2;\n                    vec4 _1167 = fa_light_texel(param_44);\n                    vec3 _1171 = normalize(_1167.xyz);\n                    int param_45 = _714 + 4;\n                    vec4 _1176 = fa_light_texel(param_45);\n                    int param_46 = _714 + 5;\n                    vec4 _1181 = fa_light_texel(param_46);\n                    if (_1153)\n                    {\n                        vec3 _1189 = -to_light;\n                        float _1196 = _1167.w;\n                        float _1212 = 0.5 / max(dot(_1189, _1171) * (sqrt(max(1.0 - (_1196 * _1196), 0.0)) / max(_1196, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1145.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1189, _1176.xyz) * _1212), 0.5 - (dot(_1189, _1181.xyz) * _1212));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1150.z > 0.5)\n                    {\n                        vec2 param_49 = _1150.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1171;\n                        vec3 param_52 = _1176.xyz;\n                        vec3 param_53 = _1181.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _4151 = _727.xyz * atten;\n    if (_718)\n    {\n        _4151 *= fa_light_tint;\n    }\n    int _1280;\n    if (_744)\n    {\n        _1280 = 0;\n    }\n    else\n    {\n        _1280 = ((_730 > 1.5) && (_730 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4151, atten, 1.0, dist, _1280);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2017;\n    if (i == 0)\n    {\n        _2017 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2033;\n        if (i == 1)\n        {\n            _2033 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2041;\n            if (i == 2)\n            {\n                _2041 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2041 = fa_shadows[24].w;\n            }\n            _2033 = _2041;\n        }\n        _2017 = _2033;\n    }\n    return _2017;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2074 = fa_shadow_depth(param, param_1);\n    float _2078;\n    if (conv.x < 0.5)\n    {\n        _2078 = _2074;\n    }\n    else\n    {\n        _2078 = (conv.y * conv.z) / (conv.z - (_2074 * (conv.z - conv.y)));\n    }\n    return _2078;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2005 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2005), sin(_2005)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2124 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2133;\n        if (k < 0.0)\n        {\n            _2133 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2133 = k;\n        }\n        float _2153 = clamp((_2133 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2124;\n            vec2 _2172 = fa_shadow_vogel(param_3, param_4, param_5) * _2153;\n            vec2 param_6 = uv + (_2172 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2184 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2184 < (zr - (length(_2172) * plane)))\n            {\n                sum += _2184;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2210 = sum / cnt;\n        float _2220;\n        if (k < 0.0)\n        {\n            _2220 = (-k) / max(_2210, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2220 = k;\n        }\n        radius = clamp(((max(zr - _2210, 0.0) * unit) * _2220) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2242 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2242; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2242;\n        float param_11 = _2124;\n        vec2 _2261 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2261 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2261) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2242);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2303 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2308 = clamp(dot(n, l), 0.0, 1.0);\n    float _2314 = sqrt(1.0 - (_2308 * _2308));\n    float _2321 = min(_2314 / max(_2308, 0.20000000298023223876953125), 4.0);\n    float _2326;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2326 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2326 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2351 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2326 * _2314)), 1.0);\n    float _2358 = _2351.x;\n    bool _2361 = _2358 < fa_shadows[ci * 1 + 16].x;\n    bool _2370;\n    if (!_2361)\n    {\n        _2370 = _2358 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2370 = _2361;\n    }\n    bool _2379;\n    if (!_2370)\n    {\n        _2379 = _2351.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2379 = _2370;\n    }\n    bool _2388;\n    if (!_2379)\n    {\n        _2388 = _2351.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2388 = _2379;\n    }\n    bool _2395;\n    if (!_2388)\n    {\n        _2395 = _2351.z > 1.0;\n    }\n    else\n    {\n        _2395 = _2388;\n    }\n    if (_2395)\n    {\n        return -1.0;\n    }\n    float _2403;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2403 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2403 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2351.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2351.z - ((_2403 * (1.0 + (0.5 * _2321))) / _2303);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2303;\n    float param_5 = _2303 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2321, 3.0)) * 0.5) / _2303;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2791 = int(fa_shadows[25].x + 0.5);\n    if (_2791 < 1)\n    {\n        return 1.0;\n    }\n    float _2806 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2791 - 1;\n    if (_2806 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2818 = _2791 > 1;\n    bool _2825;\n    if (_2818)\n    {\n        _2825 = _2806 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2825 = _2818;\n    }\n    if (_2825)\n    {\n        ci = 1;\n    }\n    bool _2829 = _2791 > 2;\n    bool _2836;\n    if (_2829)\n    {\n        _2836 = _2806 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2836 = _2829;\n    }\n    if (_2836)\n    {\n        ci = 2;\n    }\n    bool _2840 = _2791 > 3;\n    bool _2847;\n    if (_2840)\n    {\n        _2847 = _2806 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2847 = _2840;\n    }\n    if (_2847)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2791)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2873 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2873;\n        if (_2873 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2898;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2898 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2898 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2917 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2898, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2928 = clamp((_2806 - (fa_shadow_split_at(param_7) - _2917)) / _2917, 0.0, 1.0);\n        if (_2928 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2791)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2949 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2949;\n                if (_2949 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2928);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _2461 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2468;\n    if (!_2461)\n    {\n        _2468 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2468 = _2461;\n    }\n    if (_2468)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2481 = fa_light_texel(param);\n    float _2482 = _2481.x;\n    if (_2482 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2491 = int(_2482 + 0.5);\n    int param_1 = _2491;\n    vec4 _2495 = fa_light_texel(param_1);\n    int param_2 = _2491 + 1;\n    vec4 _2500 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2503 = _2495.y;\n    if (_2503 > 0.0)\n    {\n        float _2520 = 1.0 - smoothstep(0.75 * _2503, _2503, length(world - fa_shadows[27].xyz));\n        fade = _2520;\n        if (_2520 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2495.x > 1.5)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        vec3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2549 = (_2491 + 2) + (face * 6);\n    int param_6 = _2549;\n    int param_7 = _2549 + 1;\n    int param_8 = _2549 + 3;\n    vec4 _2563 = fa_light_texel(param_8);\n    int param_9 = _2549 + 4;\n    vec4 _2568 = fa_light_texel(param_9);\n    int param_10 = _2549 + 5;\n    vec4 _2573 = fa_light_texel(param_10);\n    float _2585 = _2573.x * max(dot(_2563, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2590 = clamp(dot(n, l), 0.0, 1.0);\n    float _2613 = clamp(dot(n, _2563.xyz), -1.0, 1.0);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2637 = min(sqrt(1.0 - (_2613 * _2613)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2563, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2640 = _2500.y;\n    float _2642;\n    if (_2640 > 0.0)\n    {\n        _2642 = _2640;\n    }\n    else\n    {\n        _2642 = 1.5 * _2585;\n    }\n    vec4 _2662 = vec4(world + (n * (_2642 * sqrt(1.0 - (_2590 * _2590)))), 1.0);\n    float _2666 = dot(_2563, _2662);\n    float _2669 = _2573.y;\n    if (_2666 < _2669)\n    {\n        return 1.0;\n    }\n    vec2 _2684 = vec2(dot(fa_light_texel(param_6), _2662), dot(fa_light_texel(param_7), _2662)) / vec2(_2666);\n    float _2686 = _2684.x;\n    bool _2689 = _2686 < _2568.x;\n    bool _2698;\n    if (!_2689)\n    {\n        _2698 = _2686 > _2568.z;\n    }\n    else\n    {\n        _2698 = _2689;\n    }\n    bool _2707;\n    if (!_2698)\n    {\n        _2707 = _2684.y < _2568.y;\n    }\n    else\n    {\n        _2707 = _2698;\n    }\n    bool _2716;\n    if (!_2707)\n    {\n        _2716 = _2684.y > _2568.w;\n    }\n    else\n    {\n        _2716 = _2707;\n    }\n    if (_2716)\n    {\n        return 1.0;\n    }\n    float _2722 = _2500.x;\n    float _2724;\n    if (_2722 > 0.0)\n    {\n        _2724 = _2722;\n    }\n    else\n    {\n        _2724 = 1.5 * _2585;\n    }\n    vec2 param_13 = _2684;\n    vec4 param_14 = _2568;\n    float param_15 = _2666 - (_2724 * (1.0 + (0.5 * _2637)));\n    float param_16 = _2585;\n    float param_17 = 1.0;\n    float param_18 = _2573.z * 0.25;\n    float param_19 = (_2585 * min(_2637, 3.0)) * 0.5;\n    vec3 param_20 = vec3(1.0, _2669, _2573.z);\n    int param_21 = int(_2495.z + 0.5);\n    float param_22 = _2495.w;\n    return mix(1.0, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3116 = fa_lm.z > 0.5;\n    bool _3122;\n    if (_3116)\n    {\n        int param = li;\n        _3122 = fa_light_baked(param);\n    }\n    else\n    {\n        _3122 = _3116;\n    }\n    if (_3122)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3146 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _4177 = _3146.color;\n    float _4179 = _3146.shadow;\n    if ((_3146.type == 0) && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3146.direction;\n        float _3160 = fa_shadow_factor(param_5, param_6);\n        _4179 = _3160;\n        _4177 *= _3160;\n    }\n    else\n    {\n        bool _3171 = _3146.type != 0;\n        bool _3177;\n        if (_3171)\n        {\n            _3177 = _3146.attenuation > 0.0;\n        }\n        else\n        {\n            _3177 = _3171;\n        }\n        if (_3177)\n        {\n            int param_7 = li;\n            vec3 param_8 = world_pos;\n            vec3 param_9 = gn;\n            vec3 param_10 = _3146.direction;\n            float _3189 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _4179 = _3189;\n            _4177 *= _3189;\n        }\n    }\n    return LightSample(_3146.direction, _4177, _3146.attenuation, _4179, _3146._distance, _3146.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2973 = int(fa_shadows[25].x + 0.5);\n    float _2983 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2988 = _2973 > 0;\n    bool _2997;\n    if (_2988)\n    {\n        int param = _2973 - 1;\n        _2997 = _2983 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2997 = _2988;\n    }\n    if (_2997)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3003 = _2973 > 1;\n        bool _3010;\n        if (_3003)\n        {\n            _3010 = _2983 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3010 = _3003;\n        }\n        if (_3010)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3016 = _2973 > 2;\n        bool _3023;\n        if (_3016)\n        {\n            _3023 = _2983 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3023 = _3016;\n        }\n        if (_3023)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3029 = _2973 > 3;\n        bool _3036;\n        if (_3029)\n        {\n            _3036 = _2983 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3036 = _3029;\n        }\n        if (_3036)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3993 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3993 = -_3993;\n    }\n    vec3 _3577 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3993, fa_world_tangent, fa_uv, fa_vertex_color, _3577, gl_FrontFacing);\n    Surface _3585 = fa_standard_surface(param_1);\n    vec3 _4032 = _3585.albedo;\n    float _4033 = _3585.alpha;\n    vec3 _4034 = _3585.normal;\n    float _4035 = _3585.metallic;\n    float _4036 = _3585.roughness;\n    float _4037 = _3585.occlusion;\n    vec3 _4038 = _3585.emission;\n    float _4039 = _3585.clearcoat;\n    float _4040 = _3585.clearcoat_roughness;\n    vec3 _4041 = _3585.sheen_color;\n    float _4042 = _3585.sheen_roughness;\n    float _4043 = _3585.anisotropy;\n    float _4044 = _3585.anisotropy_rotation;\n    float _4045 = _3585.specular;\n    float _4046 = _3585.ior;\n    vec3 _4047 = _3585.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3993, fa_world_tangent, fa_uv, fa_vertex_color, _3577, gl_FrontFacing);\n    Surface param_3 = _3585;\n    surface(param_2, param_3);\n    _4032 = param_3.albedo;\n    _4033 = param_3.alpha;\n    _4034 = param_3.normal;\n    _4035 = param_3.metallic;\n    _4036 = param_3.roughness;\n    _4037 = param_3.occlusion;\n    _4038 = param_3.emission;\n    _4039 = param_3.clearcoat;\n    _4040 = param_3.clearcoat_roughness;\n    _4041 = param_3.sheen_color;\n    _4042 = param_3.sheen_roughness;\n    _4043 = param_3.anisotropy;\n    _4044 = param_3.anisotropy_rotation;\n    _4045 = param_3.specular;\n    _4046 = param_3.ior;\n    _4047 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _3993;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4032 = param_6;\n    _4034 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4032;\n    }\n    else\n    {\n        vec3 _3623 = _4034;\n        vec3 _3624 = normalize(_3623);\n        _4034 = _3624;\n        vec3 param_8 = _3624;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _3993, fa_world_tangent, fa_uv, fa_vertex_color, _3577, gl_FrontFacing);\n        Surface param_10 = Surface(_4032, _4033, _4034, _4035, _4036, _4037, _4038, _4039, _4040, _4041, _4042, _4043, _4044, _4045, _4046, _4047);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _3643 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3643; ln++)\n        {\n            int param_12 = ln;\n            int _3656 = fa_cl_light(param_12);\n            bool _3659 = fa_lm.z > 0.5;\n            bool _3665;\n            if (_3659)\n            {\n                int param_13 = _3656;\n                _3665 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _3665 = _3659;\n            }\n            if (_3665)\n            {\n                continue;\n            }\n            int param_14 = _3656;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _3993;\n            LightSample _3677 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _3993, fa_world_tangent, fa_uv, fa_vertex_color, _3577, gl_FrontFacing);\n            Surface param_18 = Surface(_4032, _4033, _4034, _4035, _4036, _4037, _4038, _4039, _4040, _4041, _4042, _4043, _4044, _4045, _4046, _4047);\n            LightSample param_19 = _3677;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _3692 = result;\n    vec3 _3693 = _3692 + _4038;\n    result = _3693;\n    vec3 param_20 = _3693;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _3702 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3709;\n    if (!_3702)\n    {\n        _3709 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3709 = _3702;\n    }\n    if (_3709)\n    {\n        vec3 _3718 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3724 = dot(_3718, fa_mesh_fs_params[9].xyz);\n        bool _3728 = fa_mesh_fs_params[9].w > 0.5;\n        float _3729;\n        if (_3728)\n        {\n            _3729 = _3724;\n        }\n        else\n        {\n            _3729 = length(_3718);\n        }\n        float _3741 = _3729 - fa_mesh_fs_params[8].x;\n        if (_3741 > 0.0)\n        {\n            float _3750 = fa_mesh_fs_params[7].w * _3741;\n            float tau = _3750 * _3750;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3766;\n                if (_3728)\n                {\n                    _3766 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3724);\n                }\n                else\n                {\n                    _3766 = fa_mesh_fs_params[0].y;\n                }\n                float _3787 = mix(_3766, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3729, 0.0, 1.0));\n                float _3791 = fa_world_pos.y - _3787;\n                float _3796 = _3787 - fa_mesh_fs_params[8].z;\n                float _3801 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3804 = _3796 <= 0.0;\n                bool _3805 = !_3804;\n                bool _3811;\n                if (_3805)\n                {\n                    _3811 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3811 = _3804;\n                }\n                float _3812;\n                if (_3811)\n                {\n                    _3812 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3812 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3796, 80.0));\n                }\n                bool _3839;\n                if (_3805)\n                {\n                    _3839 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3839 = _3804;\n                }\n                float _3840;\n                if (_3839)\n                {\n                    _3840 = fa_mesh_fs_params[8].y * _3796;\n                }\n                else\n                {\n                    _3840 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3796, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3865 = _3801 <= 0.0;\n                bool _3872;\n                if (!_3865)\n                {\n                    _3872 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3872 = _3865;\n                }\n                float _3873;\n                if (_3872)\n                {\n                    _3873 = fa_mesh_fs_params[8].y * _3801;\n                }\n                else\n                {\n                    _3873 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3801, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3900;\n                if (abs(_3791) < 0.001000000047497451305389404296875)\n                {\n                    _3900 = _3812;\n                }\n                else\n                {\n                    _3900 = (_3873 - _3840) / _3791;\n                }\n                tau += (_3741 * max(_3900, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4033);\n}\n\n",
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
            "inst_name": "_320",
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
            "inst_name": "_2027",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1298 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1305;\n    if (!_1298)\n    {\n        _1305 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1305 = _1298;\n    }\n    bool _1313;\n    if (!_1305)\n    {\n        _1313 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1313 = _1305;\n    }\n    bool _1320;\n    if (!_1313)\n    {\n        _1320 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1320 = _1313;\n    }\n    bool _1327;\n    if (!_1320)\n    {\n        _1327 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1327 = _1320;\n    }\n    if (_1327)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1337 = vec4(world_pos, 1.0);\n    float _1343 = dot(fa_mesh_fs_params[16], _1337);\n    if (!(_1343 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1365 = vec2(dot(fa_mesh_fs_params[14], _1337), dot(fa_mesh_fs_params[15], _1337)) / vec2(_1343);\n    int _1369 = int(fa_mesh_fs_params[18].x);\n    int _1373 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1373) + clamp(int(floor(((_1365.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1373 - 1)) * _1369)) + clamp(int(floor(((_1365.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1369 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1449 = fa_cluster_texel(param);\n    return ivec2(int(_1449.x), int(_1449.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3089 = fa_cluster_lookup(param);\n    fa_cl_slot = _3089.x;\n    fa_cl_local = _3089.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3243 = fa_linear_to_srgb(param);\n        c = _3243;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3251 = fa_srgb_to_linear(param_1);\n            c = _3251;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _252;\n    if (i.front_facing)\n    {\n        _252 = i.world_normal;\n    }\n    else\n    {\n        _252 = -i.world_normal;\n    }\n    vec3 _276 = normalize(i.world_tangent.xyz - (_252 * dot(_252, i.world_tangent.xyz)));\n    vec3 _304 = normalize(((_276 * m.x) + ((cross(_252, _276) * i.world_tangent.w) * m.y)) + (_252 * m.z));\n    vec3 _307;\n    if (i.front_facing)\n    {\n        _307 = _304;\n    }\n    else\n    {\n        _307 = -_304;\n    }\n    return _307;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3282 = fa_tex_fix(param_2, param_3);\n    vec4 _4332 = base_t;\n    _4332.x = _3282.x;\n    _4332.y = _3282.y;\n    _4332.z = _3282.z;\n    base_t = _4332;\n    vec4 _3296 = (_4332 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4197 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3328 = fa_tex_fix(param_6, param_7);\n        vec3 _3331 = (_3328 * 2.0) - vec3(1.0);\n        vec2 _3336 = _3331.xy * fa_mesh_fs_params[6].x;\n        vec3 _4340 = _3331;\n        _4340.x = _3336.x;\n        _4340.y = _3336.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4340;\n        _4197 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3364 = fa_tex_fix(param_12, param_13);\n    vec4 _4343 = mrt;\n    _4343.x = _3364.x;\n    _4343.y = _3364.y;\n    _4343.z = _3364.z;\n    mrt = _4343;\n    vec4 _3392 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3392.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3403 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3433 = fa_tex_fix(param_20, param_21);\n    float _4202 = fa_mesh_fs_params[20].x;\n    float _4203 = fa_mesh_fs_params[20].y;\n    float _4206 = fa_mesh_fs_params[20].z;\n    float _4205 = fa_mesh_fs_params[21].w;\n    float _4208 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4202 *= _3403.y;\n            _4203 *= _3403.z;\n            _4205 *= _3392.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4206 *= mrt.x;\n            _4208 *= mrt.w;\n        }\n    }\n    return Surface(_3296.xyz, _3296.w, _4197, clamp(fa_mesh_fs_params[5].x * _3364.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3364.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3403.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3433), _4202, _4203, fa_mesh_fs_params[21].xyz, _4205, _4206, fa_mesh_fs_params[20].w, _4208, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1529 = rect.zw - rect.xy;\n    vec2 _1533 = _1529 * atlas;\n    vec2 _1537 = ddx * _1533;\n    vec2 _1541 = ddy * _1533;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1529), clamp(0.5 * log2(max(max(dot(_1537, _1537), dot(_1541, _1541)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1574 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1581;\n    if (!_1574)\n    {\n        _1581 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1581 = _1574;\n    }\n    if (_1581)\n    {\n        return;\n    }\n    vec3 _1587 = dFdx(world_pos);\n    vec3 _1590 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1594 = fa_cluster_texel(param);\n    int _1598 = int(_1594.w);\n    if (_1598 < 1)\n    {\n        return;\n    }\n    int _1608 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1608;\n    vec4 _1612 = fa_light_texel(param_1);\n    vec2 _1615 = _1612.yz;\n    int _1619 = int(_1612.w);\n    int param_2 = _1608 + 1;\n    vec4 _1624 = fa_light_texel(param_2);\n    float _1625 = _1624.x;\n    int _1631 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1635 = int(_1594.z);\n    vec3 _1900;\n    for (int k = 0; k < _1598; k++)\n    {\n        int _1648 = _1635 + k;\n        int param_3 = _1619 + (_1648 >> 2);\n        int _1665 = (_1608 + 2) + (int(fa_light_texel(param_3)[_1648 & 3]) * 7);\n        int param_4 = _1665 + 6;\n        vec4 _1670 = fa_light_texel(param_4);\n        if (((int(_1670.w + 0.5) >> _1631) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1665;\n        vec4 _1685 = fa_light_texel(param_5);\n        int param_6 = _1665 + 1;\n        vec4 _1690 = fa_light_texel(param_6);\n        int param_7 = _1665 + 2;\n        vec4 _1695 = fa_light_texel(param_7);\n        vec3 _1698 = _1685.xyz;\n        float _1703 = dot(_1698, world_pos) + _1685.w;\n        vec3 _1705 = _1690.xyz;\n        float _1710 = dot(_1705, world_pos) + _1690.w;\n        vec3 _1712 = _1695.xyz;\n        float _1717 = dot(_1712, world_pos) + _1695.w;\n        bool _1722 = abs(_1703) > 0.5;\n        bool _1730;\n        if (!_1722)\n        {\n            _1730 = abs(_1710) > 0.5;\n        }\n        else\n        {\n            _1730 = _1722;\n        }\n        bool _1738;\n        if (!_1730)\n        {\n            _1738 = abs(_1717) > 0.5;\n        }\n        else\n        {\n            _1738 = _1730;\n        }\n        if (_1738)\n        {\n            continue;\n        }\n        float _1753 = clamp(dot(geo_normal, normalize(_1712)) * _1670.z, 0.0, 1.0);\n        if (_1753 <= 0.0)\n        {\n            continue;\n        }\n        float _1773 = (clamp((0.5 - abs(_1717)) * 10.0, 0.0, 1.0) * _1753) * _1670.x;\n        vec2 _1781 = vec2(_1703 + 0.5, 0.5 - _1710);\n        vec2 _1791 = vec2(dot(_1698, _1587), dot(_1705, _1587));\n        vec2 _1801 = vec2(dot(_1698, _1590), dot(_1705, _1590));\n        int param_8 = _1665 + 5;\n        vec4 _1806 = fa_light_texel(param_8);\n        int param_9 = _1665 + 3;\n        vec4 _1811 = fa_light_texel(param_9);\n        int param_10 = _1665 + 4;\n        vec4 _1816 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1806.xyz;\n        bool _1826 = _1811.z > _1811.x;\n        if (_1826)\n        {\n            vec4 param_11 = _1811;\n            vec2 param_12 = _1781;\n            vec2 param_13 = _1615;\n            vec2 param_14 = _1791;\n            vec2 param_15 = _1801;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1625 > 0.5) && (_1625 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1852 = fa_dc_to_linear(param_16);\n                vec4 _4277 = tx;\n                _4277.x = _1852.x;\n                _4277.y = _1852.y;\n                _4277.z = _1852.z;\n                tx = _4277;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1773 * tex_a) * _1806.w, 0.0, 1.0)));\n        if (_1816.z > _1816.x)\n        {\n            vec4 param_17 = _1816;\n            vec2 param_18 = _1781;\n            vec2 param_19 = _1615;\n            vec2 param_20 = _1791;\n            vec2 param_21 = _1801;\n            vec4 _1896 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1625 > 1.5)\n            {\n                vec3 param_22 = _1896.xyz;\n                vec3 _1906 = fa_dc_to_srgb(param_22);\n                _1900 = _1906;\n            }\n            else\n            {\n                _1900 = _1896.xyz;\n            }\n            vec3 _1915 = (_1900 * 2.0) - vec3(1.0);\n            vec2 _1920 = _1915.xy * _1670.y;\n            vec3 _1942 = (normalize(_1698) * _1920.x) + (normalize(_1705) * _1920.y);\n            vec3 _1945 = normalize(normal);\n            normal = normalize(mix(_1945, normalize((_1945 * max(_1915.z, 0.0500000007450580596923828125)) + (_1942 - (_1945 * dot(_1945, _1942)))), vec3(clamp(_1773 * (_1826 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _548 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _561 = (c - (ru * hx)) - p;\n        vec3 _567 = ru * (2.0 * hx);\n        float _573 = max(dot(_567, _567), 9.9999999392252902907785028219223e-09);\n        float _577 = dot(_561, _567);\n        float t = clamp((-_577) / _573, 0.0, 1.0);\n        if (_548)\n        {\n            float _592 = dot(r, _567);\n            float _598 = _573 - (_592 * _592);\n            if (abs(_598) > (9.9999997473787516355514526367188e-06 * _573))\n            {\n                t = clamp(((dot(r, _561) * _592) - _577) / _598, 0.0, 1.0);\n            }\n        }\n        return (p + _561) + (_567 * t);\n    }\n    vec3 q = p;\n    float _630 = dot(r, axis);\n    bool _638;\n    if (_548)\n    {\n        _638 = abs(_630) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _638 = _548;\n    }\n    if (_638)\n    {\n        float _648 = dot(c - p, axis) / _630;\n        if (_648 > 0.0)\n        {\n            q = p + (r * _648);\n        }\n    }\n    vec3 _661 = q - c;\n    vec2 xy = vec2(dot(_661, ru), dot(_661, uu));\n    if (shape > 0.5)\n    {\n        float _676 = length(xy);\n        if (_676 > hx)\n        {\n            xy *= (hx / _676);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _469 = abs(d);\n    float _471 = _469.x;\n    float _473 = _469.y;\n    bool _474 = _471 >= _473;\n    bool _482;\n    if (_474)\n    {\n        _482 = _471 >= _469.z;\n    }\n    else\n    {\n        _482 = _474;\n    }\n    int _483;\n    if (_482)\n    {\n        _483 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _496;\n        if (_473 >= _469.z)\n        {\n            _496 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _496 = (d.z > 0.0) ? 4 : 5;\n        }\n        _483 = _496;\n    }\n    return _483;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _422 = dot(d, right);\n    float _426 = dot(d, up);\n    float _437;\n    if (((_422 * _422) + (_426 * _426)) > 1.0000000133514319600180897396058e-10)\n    {\n        _437 = atan(_426, _422) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _437 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_437 - floor(_437)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _714 = fa_light_base(param);\n    bool _718 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _714;\n    vec4 _722 = fa_light_texel(param_1);\n    int param_2 = _714 + 1;\n    vec4 _727 = fa_light_texel(param_2);\n    float _730 = _727.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _742 = _718 && (_730 > 2.5);\n    fa_light_is_area = _742;\n    bool _744 = _730 < 0.5;\n    vec3 l;\n    if (_744)\n    {\n        l = normalize(_722.xyz);\n        if (_718)\n        {\n            int param_3 = _714 + 6;\n            vec4 _758 = fa_light_texel(param_3);\n            if (_758.z > 0.5)\n            {\n                int param_4 = _714 + 4;\n                vec4 _768 = fa_light_texel(param_4);\n                int param_5 = _714 + 5;\n                vec4 _773 = fa_light_texel(param_5);\n                vec2 param_6 = _758.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _768.xyz) * _768.w, (-dot(world_pos, _773.xyz)) * _773.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _803 = _722.xyz;\n        vec3 _805 = _803 - world_pos;\n        vec3 to_light = _805;\n        float _808 = length(_805);\n        float reach = _808;\n        bool front = true;\n        if (_742)\n        {\n            int param_8 = _714 + 7;\n            reach = max(_808 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _714 + 4;\n            vec4 _832 = fa_light_texel(param_9);\n            int param_10 = _714 + 5;\n            vec4 _837 = fa_light_texel(param_10);\n            int param_11 = _714 + 6;\n            vec4 _842 = fa_light_texel(param_11);\n            float _843 = _842.w;\n            int param_12 = _714 + 2;\n            vec3 _850 = normalize(fa_light_texel(param_12).xyz);\n            bool _852 = _843 > 1.5;\n            bool _860;\n            if (!_852)\n            {\n                _860 = dot(_850, to_light) < 0.0;\n            }\n            else\n            {\n                _860 = _852;\n            }\n            front = _860;\n            vec3 r = vec3(0.0);\n            vec3 _869 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _873 = dot(n, n) > 0.5;\n            bool _881;\n            if (_873)\n            {\n                _881 = dot(_869, _869) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _881 = _873;\n            }\n            if (_881)\n            {\n                r = reflect(-normalize(_869), normalize(n));\n            }\n            vec3 param_13 = _803;\n            vec3 param_14 = _850;\n            vec3 param_15 = _832.xyz;\n            vec3 param_16 = _837.xyz;\n            float param_17 = _832.w;\n            float param_18 = _837.w;\n            float param_19 = _843;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _917 = length(to_light);\n        dist = _917;\n        l = to_light / vec3(max(_917, 9.9999997473787516355514526367188e-05));\n        float _931 = reach / max(_722.w, 0.001000000047497451305389404296875);\n        float _937 = clamp(1.0 - (_931 * _931), 0.0, 1.0);\n        float _939;\n        if (front)\n        {\n            _939 = _937 * _937;\n        }\n        else\n        {\n            _939 = 0.0;\n        }\n        atten = _939;\n        bool _950 = _730 < 2.5;\n        if ((_730 > 1.5) && _950)\n        {\n            int param_22 = _714 + 2;\n            vec4 _958 = fa_light_texel(param_22);\n            float _968 = _958.w;\n            int param_23 = _714 + 3;\n            vec4 _973 = fa_light_texel(param_23);\n            float _974 = _973.x;\n            float cos_inner = _974;\n            if (_974 > 1.5)\n            {\n                cos_inner = mix(_968, 1.0, 0.25);\n            }\n            atten *= smoothstep(_968, cos_inner, dot(-l, normalize(_958.xyz)));\n        }\n        if (_718 && (_730 < 1.5))\n        {\n            int param_24 = _714 + 6;\n            vec4 _998 = fa_light_texel(param_24);\n            if (_998.z > 0.5)\n            {\n                vec3 _1006 = -to_light;\n                int param_25 = _714 + 4;\n                int param_26 = _714 + 5;\n                vec3 _1020 = fa_light_texel(param_25).xyz;\n                vec3 _1024 = fa_light_texel(param_26).xyz;\n                vec3 _1033 = vec3(dot(_1006, _1020), dot(_1006, _1024), dot(_1006, cross(_1020, _1024)));\n                vec3 param_27 = _1033;\n                int _1037 = fa_cube_face(param_27);\n                int param_28 = _1037;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1064 = vec2(dot(_1033, cross(param_29, param_30)), dot(_1033, param_30)) / vec2(max(dot(_1033, param_29), 9.9999997473787516355514526367188e-05));\n                int _1068 = _1037 / 3;\n                vec2 param_31 = _998.xy + (vec2(float(_1037 - (_1068 * 3)), float(_1068)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1064.x), 0.5 - (0.5 * _1064.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _714 + 7;\n            vec4 _1098 = fa_light_texel(param_33);\n            if (_1098.z > 0.5)\n            {\n                int param_34 = _714 + 2;\n                int param_35 = _714 + 4;\n                int param_36 = _714 + 5;\n                vec2 param_37 = _1098.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_718 && _950)\n            {\n                int param_42 = _714 + 6;\n                vec4 _1145 = fa_light_texel(param_42);\n                int param_43 = _714 + 7;\n                vec4 _1150 = fa_light_texel(param_43);\n                bool _1153 = _1145.z > 0.5;\n                bool _1160;\n                if (!_1153)\n                {\n                    _1160 = _1150.z > 0.5;\n                }\n                else\n                {\n                    _1160 = _1153;\n                }\n                if (_1160)\n                {\n                    int param_44 = _714 + 2;\n                    vec4 _1167 = fa_light_texel(param_44);\n                    vec3 _1171 = normalize(_1167.xyz);\n                    int param_45 = _714 + 4;\n                    vec4 _1176 = fa_light_texel(param_45);\n                    int param_46 = _714 + 5;\n                    vec4 _1181 = fa_light_texel(param_46);\n                    if (_1153)\n                    {\n                        vec3 _1189 = -to_light;\n                        float _1196 = _1167.w;\n                        float _1212 = 0.5 / max(dot(_1189, _1171) * (sqrt(max(1.0 - (_1196 * _1196), 0.0)) / max(_1196, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1145.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1189, _1176.xyz) * _1212), 0.5 - (dot(_1189, _1181.xyz) * _1212));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1150.z > 0.5)\n                    {\n                        vec2 param_49 = _1150.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1171;\n                        vec3 param_52 = _1176.xyz;\n                        vec3 param_53 = _1181.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _4151 = _727.xyz * atten;\n    if (_718)\n    {\n        _4151 *= fa_light_tint;\n    }\n    int _1280;\n    if (_744)\n    {\n        _1280 = 0;\n    }\n    else\n    {\n        _1280 = ((_730 > 1.5) && (_730 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4151, atten, 1.0, dist, _1280);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2017;\n    if (i == 0)\n    {\n        _2017 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2033;\n        if (i == 1)\n        {\n            _2033 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2041;\n            if (i == 2)\n            {\n                _2041 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2041 = fa_shadows[24].w;\n            }\n            _2033 = _2041;\n        }\n        _2017 = _2033;\n    }\n    return _2017;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2074 = fa_shadow_depth(param, param_1);\n    float _2078;\n    if (conv.x < 0.5)\n    {\n        _2078 = _2074;\n    }\n    else\n    {\n        _2078 = (conv.y * conv.z) / (conv.z - (_2074 * (conv.z - conv.y)));\n    }\n    return _2078;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2005 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2005), sin(_2005)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2124 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2133;\n        if (k < 0.0)\n        {\n            _2133 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2133 = k;\n        }\n        float _2153 = clamp((_2133 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2124;\n            vec2 _2172 = fa_shadow_vogel(param_3, param_4, param_5) * _2153;\n            vec2 param_6 = uv + (_2172 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2184 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2184 < (zr - (length(_2172) * plane)))\n            {\n                sum += _2184;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2210 = sum / cnt;\n        float _2220;\n        if (k < 0.0)\n        {\n            _2220 = (-k) / max(_2210, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2220 = k;\n        }\n        radius = clamp(((max(zr - _2210, 0.0) * unit) * _2220) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2242 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2242; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2242;\n        float param_11 = _2124;\n        vec2 _2261 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2261 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2261) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2242);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2303 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2308 = clamp(dot(n, l), 0.0, 1.0);\n    float _2314 = sqrt(1.0 - (_2308 * _2308));\n    float _2321 = min(_2314 / max(_2308, 0.20000000298023223876953125), 4.0);\n    float _2326;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2326 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2326 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2351 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2326 * _2314)), 1.0);\n    float _2358 = _2351.x;\n    bool _2361 = _2358 < fa_shadows[ci * 1 + 16].x;\n    bool _2370;\n    if (!_2361)\n    {\n        _2370 = _2358 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2370 = _2361;\n    }\n    bool _2379;\n    if (!_2370)\n    {\n        _2379 = _2351.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2379 = _2370;\n    }\n    bool _2388;\n    if (!_2379)\n    {\n        _2388 = _2351.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2388 = _2379;\n    }\n    bool _2395;\n    if (!_2388)\n    {\n        _2395 = _2351.z > 1.0;\n    }\n    else\n    {\n        _2395 = _2388;\n    }\n    if (_2395)\n    {\n        return -1.0;\n    }\n    float _2403;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2403 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2403 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2351.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2351.z - ((_2403 * (1.0 + (0.5 * _2321))) / _2303);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2303;\n    float param_5 = _2303 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2321, 3.0)) * 0.5) / _2303;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2791 = int(fa_shadows[25].x + 0.5);\n    if (_2791 < 1)\n    {\n        return 1.0;\n    }\n    float _2806 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2791 - 1;\n    if (_2806 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2818 = _2791 > 1;\n    bool _2825;\n    if (_2818)\n    {\n        _2825 = _2806 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2825 = _2818;\n    }\n    if (_2825)\n    {\n        ci = 1;\n    }\n    bool _2829 = _2791 > 2;\n    bool _2836;\n    if (_2829)\n    {\n        _2836 = _2806 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2836 = _2829;\n    }\n    if (_2836)\n    {\n        ci = 2;\n    }\n    bool _2840 = _2791 > 3;\n    bool _2847;\n    if (_2840)\n    {\n        _2847 = _2806 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2847 = _2840;\n    }\n    if (_2847)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2791)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2873 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2873;\n        if (_2873 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2898;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2898 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2898 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2917 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2898, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2928 = clamp((_2806 - (fa_shadow_split_at(param_7) - _2917)) / _2917, 0.0, 1.0);\n        if (_2928 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2791)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2949 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2949;\n                if (_2949 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2928);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _2461 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2468;\n    if (!_2461)\n    {\n        _2468 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2468 = _2461;\n    }\n    if (_2468)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2481 = fa_light_texel(param);\n    float _2482 = _2481.x;\n    if (_2482 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2491 = int(_2482 + 0.5);\n    int param_1 = _2491;\n    vec4 _2495 = fa_light_texel(param_1);\n    int param_2 = _2491 + 1;\n    vec4 _2500 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2503 = _2495.y;\n    if (_2503 > 0.0)\n    {\n        float _2520 = 1.0 - smoothstep(0.75 * _2503, _2503, length(world - fa_shadows[27].xyz));\n        fade = _2520;\n        if (_2520 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2495.x > 1.5)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        vec3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2549 = (_2491 + 2) + (face * 6);\n    int param_6 = _2549;\n    int param_7 = _2549 + 1;\n    int param_8 = _2549 + 3;\n    vec4 _2563 = fa_light_texel(param_8);\n    int param_9 = _2549 + 4;\n    vec4 _2568 = fa_light_texel(param_9);\n    int param_10 = _2549 + 5;\n    vec4 _2573 = fa_light_texel(param_10);\n    float _2585 = _2573.x * max(dot(_2563, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2590 = clamp(dot(n, l), 0.0, 1.0);\n    float _2613 = clamp(dot(n, _2563.xyz), -1.0, 1.0);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2637 = min(sqrt(1.0 - (_2613 * _2613)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2563, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2640 = _2500.y;\n    float _2642;\n    if (_2640 > 0.0)\n    {\n        _2642 = _2640;\n    }\n    else\n    {\n        _2642 = 1.5 * _2585;\n    }\n    vec4 _2662 = vec4(world + (n * (_2642 * sqrt(1.0 - (_2590 * _2590)))), 1.0);\n    float _2666 = dot(_2563, _2662);\n    float _2669 = _2573.y;\n    if (_2666 < _2669)\n    {\n        return 1.0;\n    }\n    vec2 _2684 = vec2(dot(fa_light_texel(param_6), _2662), dot(fa_light_texel(param_7), _2662)) / vec2(_2666);\n    float _2686 = _2684.x;\n    bool _2689 = _2686 < _2568.x;\n    bool _2698;\n    if (!_2689)\n    {\n        _2698 = _2686 > _2568.z;\n    }\n    else\n    {\n        _2698 = _2689;\n    }\n    bool _2707;\n    if (!_2698)\n    {\n        _2707 = _2684.y < _2568.y;\n    }\n    else\n    {\n        _2707 = _2698;\n    }\n    bool _2716;\n    if (!_2707)\n    {\n        _2716 = _2684.y > _2568.w;\n    }\n    else\n    {\n        _2716 = _2707;\n    }\n    if (_2716)\n    {\n        return 1.0;\n    }\n    float _2722 = _2500.x;\n    float _2724;\n    if (_2722 > 0.0)\n    {\n        _2724 = _2722;\n    }\n    else\n    {\n        _2724 = 1.5 * _2585;\n    }\n    vec2 param_13 = _2684;\n    vec4 param_14 = _2568;\n    float param_15 = _2666 - (_2724 * (1.0 + (0.5 * _2637)));\n    float param_16 = _2585;\n    float param_17 = 1.0;\n    float param_18 = _2573.z * 0.25;\n    float param_19 = (_2585 * min(_2637, 3.0)) * 0.5;\n    vec3 param_20 = vec3(1.0, _2669, _2573.z);\n    int param_21 = int(_2495.z + 0.5);\n    float param_22 = _2495.w;\n    return mix(1.0, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3116 = fa_lm.z > 0.5;\n    bool _3122;\n    if (_3116)\n    {\n        int param = li;\n        _3122 = fa_light_baked(param);\n    }\n    else\n    {\n        _3122 = _3116;\n    }\n    if (_3122)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3146 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _4177 = _3146.color;\n    float _4179 = _3146.shadow;\n    if ((_3146.type == 0) && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3146.direction;\n        float _3160 = fa_shadow_factor(param_5, param_6);\n        _4179 = _3160;\n        _4177 *= _3160;\n    }\n    else\n    {\n        bool _3171 = _3146.type != 0;\n        bool _3177;\n        if (_3171)\n        {\n            _3177 = _3146.attenuation > 0.0;\n        }\n        else\n        {\n            _3177 = _3171;\n        }\n        if (_3177)\n        {\n            int param_7 = li;\n            vec3 param_8 = world_pos;\n            vec3 param_9 = gn;\n            vec3 param_10 = _3146.direction;\n            float _3189 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _4179 = _3189;\n            _4177 *= _3189;\n        }\n    }\n    return LightSample(_3146.direction, _4177, _3146.attenuation, _4179, _3146._distance, _3146.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2973 = int(fa_shadows[25].x + 0.5);\n    float _2983 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2988 = _2973 > 0;\n    bool _2997;\n    if (_2988)\n    {\n        int param = _2973 - 1;\n        _2997 = _2983 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2997 = _2988;\n    }\n    if (_2997)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3003 = _2973 > 1;\n        bool _3010;\n        if (_3003)\n        {\n            _3010 = _2983 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3010 = _3003;\n        }\n        if (_3010)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3016 = _2973 > 2;\n        bool _3023;\n        if (_3016)\n        {\n            _3023 = _2983 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3023 = _3016;\n        }\n        if (_3023)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3029 = _2973 > 3;\n        bool _3036;\n        if (_3029)\n        {\n            _3036 = _2983 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3036 = _3029;\n        }\n        if (_3036)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3993 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3993 = -_3993;\n    }\n    vec3 _3577 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3993, fa_world_tangent, fa_uv, fa_vertex_color, _3577, gl_FrontFacing);\n    Surface _3585 = fa_standard_surface(param_1);\n    vec3 _4032 = _3585.albedo;\n    float _4033 = _3585.alpha;\n    vec3 _4034 = _3585.normal;\n    float _4035 = _3585.metallic;\n    float _4036 = _3585.roughness;\n    float _4037 = _3585.occlusion;\n    vec3 _4038 = _3585.emission;\n    float _4039 = _3585.clearcoat;\n    float _4040 = _3585.clearcoat_roughness;\n    vec3 _4041 = _3585.sheen_color;\n    float _4042 = _3585.sheen_roughness;\n    float _4043 = _3585.anisotropy;\n    float _4044 = _3585.anisotropy_rotation;\n    float _4045 = _3585.specular;\n    float _4046 = _3585.ior;\n    vec3 _4047 = _3585.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3993, fa_world_tangent, fa_uv, fa_vertex_color, _3577, gl_FrontFacing);\n    Surface param_3 = _3585;\n    surface(param_2, param_3);\n    _4032 = param_3.albedo;\n    _4033 = param_3.alpha;\n    _4034 = param_3.normal;\n    _4035 = param_3.metallic;\n    _4036 = param_3.roughness;\n    _4037 = param_3.occlusion;\n    _4038 = param_3.emission;\n    _4039 = param_3.clearcoat;\n    _4040 = param_3.clearcoat_roughness;\n    _4041 = param_3.sheen_color;\n    _4042 = param_3.sheen_roughness;\n    _4043 = param_3.anisotropy;\n    _4044 = param_3.anisotropy_rotation;\n    _4045 = param_3.specular;\n    _4046 = param_3.ior;\n    _4047 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _3993;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4032 = param_6;\n    _4034 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4032;\n    }\n    else\n    {\n        vec3 _3623 = _4034;\n        vec3 _3624 = normalize(_3623);\n        _4034 = _3624;\n        vec3 param_8 = _3624;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _3993, fa_world_tangent, fa_uv, fa_vertex_color, _3577, gl_FrontFacing);\n        Surface param_10 = Surface(_4032, _4033, _4034, _4035, _4036, _4037, _4038, _4039, _4040, _4041, _4042, _4043, _4044, _4045, _4046, _4047);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _3643 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3643; ln++)\n        {\n            int param_12 = ln;\n            int _3656 = fa_cl_light(param_12);\n            bool _3659 = fa_lm.z > 0.5;\n            bool _3665;\n            if (_3659)\n            {\n                int param_13 = _3656;\n                _3665 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _3665 = _3659;\n            }\n            if (_3665)\n            {\n                continue;\n            }\n            int param_14 = _3656;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _3993;\n            LightSample _3677 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _3993, fa_world_tangent, fa_uv, fa_vertex_color, _3577, gl_FrontFacing);\n            Surface param_18 = Surface(_4032, _4033, _4034, _4035, _4036, _4037, _4038, _4039, _4040, _4041, _4042, _4043, _4044, _4045, _4046, _4047);\n            LightSample param_19 = _3677;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _3692 = result;\n    vec3 _3693 = _3692 + _4038;\n    result = _3693;\n    vec3 param_20 = _3693;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _3702 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3709;\n    if (!_3702)\n    {\n        _3709 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3709 = _3702;\n    }\n    if (_3709)\n    {\n        vec3 _3718 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3724 = dot(_3718, fa_mesh_fs_params[9].xyz);\n        bool _3728 = fa_mesh_fs_params[9].w > 0.5;\n        float _3729;\n        if (_3728)\n        {\n            _3729 = _3724;\n        }\n        else\n        {\n            _3729 = length(_3718);\n        }\n        float _3741 = _3729 - fa_mesh_fs_params[8].x;\n        if (_3741 > 0.0)\n        {\n            float _3750 = fa_mesh_fs_params[7].w * _3741;\n            float tau = _3750 * _3750;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3766;\n                if (_3728)\n                {\n                    _3766 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3724);\n                }\n                else\n                {\n                    _3766 = fa_mesh_fs_params[0].y;\n                }\n                float _3787 = mix(_3766, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3729, 0.0, 1.0));\n                float _3791 = fa_world_pos.y - _3787;\n                float _3796 = _3787 - fa_mesh_fs_params[8].z;\n                float _3801 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3804 = _3796 <= 0.0;\n                bool _3805 = !_3804;\n                bool _3811;\n                if (_3805)\n                {\n                    _3811 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3811 = _3804;\n                }\n                float _3812;\n                if (_3811)\n                {\n                    _3812 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3812 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3796, 80.0));\n                }\n                bool _3839;\n                if (_3805)\n                {\n                    _3839 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3839 = _3804;\n                }\n                float _3840;\n                if (_3839)\n                {\n                    _3840 = fa_mesh_fs_params[8].y * _3796;\n                }\n                else\n                {\n                    _3840 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3796, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3865 = _3801 <= 0.0;\n                bool _3872;\n                if (!_3865)\n                {\n                    _3872 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3872 = _3865;\n                }\n                float _3873;\n                if (_3872)\n                {\n                    _3873 = fa_mesh_fs_params[8].y * _3801;\n                }\n                else\n                {\n                    _3873 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3801, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3900;\n                if (abs(_3791) < 0.001000000047497451305389404296875)\n                {\n                    _3900 = _3812;\n                }\n                else\n                {\n                    _3900 = (_3873 - _3840) / _3791;\n                }\n                tau += (_3741 * max(_3900, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4033);\n}\n\n",
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
            "inst_name": "_320",
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
            "inst_name": "_2027",
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
